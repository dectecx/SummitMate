// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/collab_logic.dart';

/// Polls, their options and the votes. Offline-first like the other trip data.
///
/// Authorship: `user_id` and `created_by` are never uploaded (the server sets them). Locally they hold
/// the signed-in account's id, or null as a guest; sign-in fills them in and re-keys the votes.
class PollRepository {
  PollRepository(
    this._db,
    this._outbox,
    this._myId, {
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
  }) : _uuid = uuid,
       _now = now ?? DateTime.now;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final String? Function() _myId;
  final Uuid _uuid;
  final DateTime Function() _now;

  Stream<List<Poll>> watchPolls(String tripId) =>
      (_db.select(_db.polls)
            ..where((p) => p.tripId.equals(tripId))
            ..orderBy([
              (p) => OrderingTerm.asc(p.createdAt),
              (p) => OrderingTerm.asc(p.id),
            ]))
          .watch();

  Stream<List<PollOption>> watchOptions(String tripId) => (_db.select(
    _db.pollOptions,
  )..where((o) => o.tripId.equals(tripId))).watch();

  Stream<List<PollVote>> watchVotes(String tripId) => (_db.select(
    _db.pollVotes,
  )..where((v) => v.tripId.equals(tripId))).watch();

  // ---------------------------------------------------------------- polls

  /// Creates a poll with its options in one transaction. Throws [ArgumentError] for invalid input.
  Future<String> create(
    String tripId, {
    required String title,
    String description = '',
    required List<String> options,
    DateTime? deadline,
    bool allowMultiple = false,
    bool allowAddOption = false,
    bool blind = false,
  }) async {
    final texts = cleanOptions(options);
    final error = validatePollDraft(title, texts);
    if (error != null) throw ArgumentError(error);
    final id = _uuid.v7();
    final name = title.trim();
    final note = description.trim();
    await _db.transaction(() async {
      await _db
          .into(_db.polls)
          .insert(
            PollsCompanion.insert(
              id: id,
              tripId: tripId,
              title: name,
              description: Value(note),
              deadline: Value(deadline),
              allowMultiple: Value(allowMultiple),
              allowAddOption: Value(allowAddOption),
              blind: Value(blind),
              createdAt: _now(),
            ),
          );
      await _outbox.upsert('polls', id, {
        'trip_id': tripId,
        'title': name,
        'description': note,
        'deadline': deadline,
        'allow_multiple': allowMultiple,
        'allow_add_option': allowAddOption,
        'blind': blind,
        'status': 'open',
      }, isCreate: true);
      for (var i = 0; i < texts.length; i++) {
        await _insertOption(tripId, id, texts[i], i);
      }
    });
    return id;
  }

  /// Closing ends voting at once; reopening lets it continue (until the deadline, if any).
  Future<void> setClosed(String pollId, bool closed) async {
    final status = closed ? 'closed' : 'open';
    await _db.transaction(() async {
      await (_db.update(_db.polls)..where((p) => p.id.equals(pollId))).write(
        PollsCompanion(status: Value(status)),
      );
      await _outbox.upsert('polls', pollId, {'status': status});
    });
  }

  /// Removes the poll with its options and votes.
  Future<void> delete(String pollId) => _db.transaction(() async {
    await _outbox.delete('polls', pollId);
    await (_db.delete(
      _db.polls,
    )..where((p) => p.id.equals(pollId))).go(); // options and votes cascade
  });

  // ---------------------------------------------------------------- options

  /// Adds an option at the end. Who may do it is decided by `canAddOption` and, finally, by the server.
  Future<String> addOption(String pollId, String text) async {
    final error = validateOptionText(text);
    if (error != null) throw ArgumentError(error);
    late final String id;
    await _db.transaction(() async {
      final poll = await (_db.select(
        _db.polls,
      )..where((p) => p.id.equals(pollId))).getSingle();
      final count = await (_db.select(
        _db.pollOptions,
      )..where((o) => o.pollId.equals(pollId))).get();
      if (count.length >= pollOptionMaxCount) {
        throw ArgumentError('最多 $pollOptionMaxCount 個選項');
      }
      final last = count.fold<int>(
        -1,
        (m, o) => o.sortOrder > m ? o.sortOrder : m,
      );
      id = await _insertOption(poll.tripId, pollId, text.trim(), last + 1);
    });
    return id;
  }

  /// Removes an option and the votes for it.
  Future<void> deleteOption(String optionId) => _db.transaction(() async {
    await _outbox.delete('poll_options', optionId);
    await (_db.delete(
      _db.pollOptions,
    )..where((o) => o.id.equals(optionId))).go(); // votes cascade
  });

  Future<String> _insertOption(
    String tripId,
    String pollId,
    String text,
    int order,
  ) async {
    final id = _uuid.v7();
    await _db
        .into(_db.pollOptions)
        .insert(
          PollOptionsCompanion.insert(
            id: id,
            pollId: pollId,
            tripId: tripId,
            label: text,
            sortOrder: Value(order),
            createdBy: Value(_myId()),
          ),
        );
    await _outbox.upsert('poll_options', id, {
      'poll_id': pollId,
      'trip_id': tripId,
      'text': text,
      'sort_order': order,
    }, isCreate: true);
    return id;
  }

  // ---------------------------------------------------------------- votes

  String get _voter => _myId() ?? guestVoterId;

  /// Taps an option: in a multiple-choice poll it flips my vote for that option; in a single-choice
  /// poll it selects it (moving my vote) or, if it is already mine, takes the vote back.
  Future<void> toggle(String optionId) => _db.transaction(() async {
    if (await _hasVote(voteIdFor(optionId, _voter))) {
      await unvote(optionId);
    } else {
      await vote(optionId);
    }
  });

  /// Casts my vote for [optionId]. In a single-choice poll my vote for any other option is retracted
  /// in the same transaction. Voting again for the same option changes nothing.
  Future<void> vote(String optionId) => _db.transaction(() async {
    final option = await (_db.select(
      _db.pollOptions,
    )..where((o) => o.id.equals(optionId))).getSingle();
    final poll = await (_db.select(
      _db.polls,
    )..where((p) => p.id.equals(option.pollId))).getSingle();
    final me = _voter;
    if (!poll.allowMultiple) {
      final mine =
          await (_db.select(_db.pollVotes)..where(
                (v) =>
                    v.pollId.equals(poll.id) &
                    v.optionId.equals(optionId).not(),
              ))
              .get();
      for (final v in mine) {
        if (v.id == voteIdFor(v.optionId, me)) await _retract(v.id);
      }
    }
    final id = voteIdFor(optionId, me);
    if (await _hasVote(id)) return;
    await _db
        .into(_db.pollVotes)
        .insert(
          PollVotesCompanion.insert(
            id: id,
            pollId: poll.id,
            optionId: optionId,
            tripId: poll.tripId,
            userId: Value(_myId()),
            updatedAt: _now(),
          ),
        );
    await _outbox.upsert(
      'poll_votes',
      id,
      {'poll_id': poll.id, 'option_id': optionId, 'trip_id': poll.tripId},
      isCreate: true,
      revive: true,
    );
  });

  /// Takes my vote for [optionId] back (a tombstone is queued so other devices follow).
  Future<void> unvote(String optionId) => _db.transaction(() async {
    final id = voteIdFor(optionId, _voter);
    if (await _hasVote(id)) await _retract(id);
  });

  Future<bool> _hasVote(String id) async =>
      await (_db.select(
        _db.pollVotes,
      )..where((v) => v.id.equals(id))).getSingleOrNull() !=
      null;

  Future<void> _retract(String id) async {
    await _outbox.delete('poll_votes', id);
    await (_db.delete(_db.pollVotes)..where((v) => v.id.equals(id))).go();
  }
}
