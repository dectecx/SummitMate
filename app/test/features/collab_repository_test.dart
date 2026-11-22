import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/collab/data/message_repository.dart';
import 'package:summitmate/features/collab/data/poll_repository.dart';
import 'package:summitmate/features/collab/domain/collab_logic.dart';
import 'package:summitmate/features/favorites/data/favorite_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';

import '../core/support.dart';

void main() {
  late AppDatabase db;
  late OutboxWriter writer;
  late MessageRepository messages;
  late PollRepository polls;
  late FavoriteRepository favorites;
  late String trip;
  String? me = 'me';
  var tick = 0;

  setUp(() async {
    db = memoryDb();
    writer = OutboxWriter(db);
    me = 'me';
    tick = 0;
    DateTime now() => DateTime.utc(2026, 5, 1, 10, 0, tick++);
    messages = MessageRepository(db, writer, () => me, now: now);
    polls = PollRepository(db, writer, () => me, now: now);
    favorites = FavoriteRepository(db, writer);
    trip = await TripRepository(
      db,
      writer,
    ).create(name: 't', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 2));
    await db.delete(db.outbox).go(); // pretend the trip was uploaded
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> lastPatch() async =>
      patchOf((await db.select(db.outbox).get()).last);

  group('messages', () {
    test('a message is stored and queued without user_id', () async {
      final id = await messages.add(trip, '  hello  ');

      final row = await db.select(db.tripMessages).getSingle();
      expect(
        [row.id, row.body, row.userId, row.parentId],
        [id, 'hello', 'me', null],
      );
      expect(await opSummary(db), ['upsert:trip_messages/$id']);
      final op = (await db.select(db.outbox).get()).single;
      expect(op.isCreate, isTrue);
      expect(patchOf(op), {'trip_id': trip, 'body': 'hello'});
    });

    test('written as a guest, the author stays empty', () async {
      me = null;
      await messages.add(trip, 'hi');
      expect((await db.select(db.tripMessages).getSingle()).userId, isNull);
    });

    test('a reply carries its parent; replying to a reply or a missing message is refused', () async {
      final a = await messages.add(trip, 'a');
      final r = await messages.add(trip, 'r', parentId: a);
      expect(await lastPatch(), {'trip_id': trip, 'parent_id': a, 'body': 'r'});
      await expectLater(
        messages.add(trip, 'rr', parentId: r),
        throwsArgumentError,
      );
      await expectLater(
        messages.add(trip, 'x', parentId: 'nope'),
        throwsArgumentError,
      );
      expect(await db.select(db.tripMessages).get(), hasLength(2));
    });

    test('invalid bodies are refused before anything is written', () async {
      await expectLater(messages.add(trip, '   '), throwsArgumentError);
      await expectLater(messages.add(trip, 'x' * 1001), throwsArgumentError);
      expect(await db.select(db.tripMessages).get(), isEmpty);
      expect(await opSummary(db), isEmpty);
    });

    test(
      'editing changes only the body, and merges into the pending creation',
      () async {
        final id = await messages.add(trip, 'one');
        await messages.edit(id, 'two');
        expect((await db.select(db.tripMessages).getSingle()).body, 'two');
        expect(await opSummary(db), ['upsert:trip_messages/$id']);
        expect(await lastPatch(), {'trip_id': trip, 'body': 'two'});
      },
    );

    test('deleting a message that never reached the server leaves no trace; replies stay', () async {
      final a = await messages.add(trip, 'a');
      final r = await messages.add(trip, 'r', parentId: a);
      await messages.delete(a);
      expect((await db.select(db.tripMessages).get()).map((m) => m.id), [r]);
      expect(await opSummary(db), ['upsert:trip_messages/$r']);
    });

    test('deleting an uploaded message queues a tombstone', () async {
      final a = await messages.add(trip, 'a');
      await db
          .update(db.outbox)
          .write(const OutboxCompanion(sent: Value(true)));
      await messages.delete(a);
      expect(await opSummary(db), ['delete:trip_messages/$a']);
    });

    test('watch lists messages oldest first', () async {
      final a = await messages.add(trip, 'a');
      final b = await messages.add(trip, 'b');
      expect((await messages.watch(trip).first).map((m) => m.id), [a, b]);
    });
  });

  group('polls', () {
    Future<String> newPoll({
      bool multiple = false,
      List<String> options = const ['A', 'B', 'C'],
    }) => polls.create(
      trip,
      title: '  去哪  ',
      description: ' d ',
      options: options,
      allowMultiple: multiple,
    );

    test('creating stores the poll and its options and queues them together, without user_id', () async {
      final deadline = DateTime.utc(2026, 5, 9, 12);
      final id = await polls.create(
        trip,
        title: 'T',
        options: [' A ', '', 'B'],
        deadline: deadline,
        allowAddOption: true,
        blind: true,
      );

      final p = await db.select(db.polls).getSingle();
      expect(
        [p.title, p.status, p.blind, p.allowAddOption, p.allowMultiple],
        ['T', 'open', true, true, false],
      );
      final opts = await (db.select(
        db.pollOptions,
      )..orderBy([(o) => OrderingTerm.asc(o.sortOrder)])).get();
      expect(opts.map((o) => [o.label, o.sortOrder, o.createdBy]), [
        ['A', 0, 'me'],
        ['B', 1, 'me'],
      ]);

      final ops = await db.select(db.outbox).get();
      expect(ops.map((o) => o.entity), [
        'polls',
        'poll_options',
        'poll_options',
      ]);
      expect(patchOf(ops.first), {
        'trip_id': trip,
        'title': 'T',
        'description': '',
        'deadline': '2026-05-09T12:00:00.000Z',
        'allow_multiple': false,
        'allow_add_option': true,
        'blind': true,
        'status': 'open',
      });
      expect(patchOf(ops[1]), {
        'poll_id': id,
        'trip_id': trip,
        'text': 'A',
        'sort_order': 0,
      });
      expect(
        ops.every(
          (o) =>
              !patchOf(o).containsKey('user_id') &&
              !patchOf(o).containsKey('created_by'),
        ),
        isTrue,
      );
    });

    test('invalid polls are refused and leave nothing behind', () async {
      await expectLater(
        polls.create(trip, title: '', options: ['a', 'b']),
        throwsArgumentError,
      );
      await expectLater(
        polls.create(trip, title: 't', options: ['a']),
        throwsArgumentError,
      );
      await expectLater(
        polls.create(
          trip,
          title: 't',
          options: [for (var i = 0; i < 21; i++) 'o$i'],
        ),
        throwsArgumentError,
      );
      expect(await db.select(db.polls).get(), isEmpty);
      expect(await opSummary(db), isEmpty);
    });

    test('closing and reopening change only the status', () async {
      final id = await newPoll();
      await db.delete(db.outbox).go();
      await polls.setClosed(id, true);
      expect((await db.select(db.polls).getSingle()).status, 'closed');
      expect(await lastPatch(), {'status': 'closed'});
      await polls.setClosed(id, false);
      expect((await db.select(db.polls).getSingle()).status, 'open');
      expect(await lastPatch(), {'status': 'open'});
    });

    test(
      'deleting a poll removes its options and votes and queues one tombstone',
      () async {
        final id = await newPoll();
        final opt = (await db.select(db.pollOptions).get()).first;
        await polls.vote(opt.id);
        await db
            .update(db.outbox)
            .write(const OutboxCompanion(sent: Value(true)));

        await polls.delete(id);

        expect(await db.select(db.pollOptions).get(), isEmpty);
        expect(await db.select(db.pollVotes).get(), isEmpty);
        expect(await opSummary(db), ['delete:polls/$id']);
      },
    );

    test('adding an option appends it with the next sort order', () async {
      final id = await newPoll(options: ['A', 'B']);
      await db.delete(db.outbox).go();
      final o = await polls.addOption(id, ' C ');
      final row = await (db.select(
        db.pollOptions,
      )..where((x) => x.id.equals(o))).getSingle();
      expect([row.label, row.sortOrder, row.createdBy], ['C', 2, 'me']);
      expect(await lastPatch(), {
        'poll_id': id,
        'trip_id': trip,
        'text': 'C',
        'sort_order': 2,
      });
      await expectLater(polls.addOption(id, ' '), throwsArgumentError);
    });

    test('a poll cannot grow beyond 20 options', () async {
      final id = await newPoll(options: [for (var i = 0; i < 20; i++) 'o$i']);
      await expectLater(polls.addOption(id, 'one more'), throwsArgumentError);
    });

    test('deleting an option removes its votes', () async {
      await newPoll();
      final opts = await db.select(db.pollOptions).get();
      await polls.vote(opts.first.id);
      await polls.deleteOption(opts.first.id);
      expect(await db.select(db.pollOptions).get(), hasLength(2));
      expect(await db.select(db.pollVotes).get(), isEmpty);
    });
  });

  group('votes', () {
    late String pollId;
    late List<PollOption> opts;

    Future<void> seed({bool multiple = false}) async {
      pollId = await polls.create(
        trip,
        title: 'T',
        options: ['A', 'B', 'C'],
        allowMultiple: multiple,
      );
      opts = await (db.select(
        db.pollOptions,
      )..orderBy([(o) => OrderingTerm.asc(o.sortOrder)])).get();
      await db.delete(db.outbox).go();
    }

    Future<List<String>> myOptions() async =>
        [for (final v in await db.select(db.pollVotes).get()) v.optionId]
          ..sort();

    test(
      'a vote has the deterministic id and uploads only poll, option and trip',
      () async {
        await seed();
        await polls.vote(opts[0].id);

        final id = voteIdFor(opts[0].id, 'me');
        final v = await db.select(db.pollVotes).getSingle();
        expect([v.id, v.userId, v.pollId, v.tripId], [id, 'me', pollId, trip]);
        final op = (await db.select(db.outbox).get()).single;
        expect([op.entity, op.entityId, op.isCreate], ['poll_votes', id, true]);
        expect(patchOf(op), {
          'poll_id': pollId,
          'option_id': opts[0].id,
          'trip_id': trip,
        });
      },
    );

    test('a guest\'s vote uses the placeholder voter until sign-in', () async {
      me = null;
      await seed();
      await polls.vote(opts[0].id);
      final v = await db.select(db.pollVotes).getSingle();
      expect([v.id, v.userId], [voteIdFor(opts[0].id, guestVoterId), null]);
    });

    test(
      'single choice: voting another option moves my vote in one step',
      () async {
        await seed();
        await polls.vote(opts[0].id);
        await db
            .update(db.outbox)
            .write(const OutboxCompanion(sent: Value(true)));
        await polls.vote(opts[1].id);

        expect(await myOptions(), [opts[1].id]);
        expect(await opSummary(db), [
          'delete:poll_votes/${voteIdFor(opts[0].id, 'me')}',
          'upsert:poll_votes/${voteIdFor(opts[1].id, 'me')}',
        ]);
      },
    );

    test('single choice: moving a vote that never left the device just replaces it', () async {
      await seed();
      await polls.vote(opts[0].id);
      await polls.vote(opts[1].id);
      expect(await opSummary(db), [
        'upsert:poll_votes/${voteIdFor(opts[1].id, 'me')}',
      ]);
    });

    test('other people\'s votes are not touched by mine', () async {
      await seed();
      await db
          .into(db.pollVotes)
          .insert(
            PollVotesCompanion.insert(
              id: voteIdFor(opts[0].id, 'other'),
              pollId: pollId,
              optionId: opts[0].id,
              tripId: trip,
              userId: const Value('other'),
              updatedAt: DateTime.utc(2026, 5, 1),
            ),
          );
      await polls.vote(opts[1].id);
      await polls.vote(opts[2].id);
      expect(
        (await db.select(db.pollVotes).get()).map((v) => v.userId),
        unorderedEquals(['other', 'me']),
      );
    });

    test('voting twice for the same option changes nothing', () async {
      await seed();
      await polls.vote(opts[0].id);
      await polls.vote(opts[0].id);
      expect(await opSummary(db), hasLength(1));
    });

    test('toggle: single choice selects, switches and takes back; multiple choice flips each option', () async {
      await seed();
      await polls.toggle(opts[0].id);
      await polls.toggle(opts[1].id);
      expect(await myOptions(), [opts[1].id]);
      await polls.toggle(opts[1].id);
      expect(await myOptions(), isEmpty);

      await polls.delete(pollId);
      await seed(multiple: true);
      await polls.toggle(opts[0].id);
      await polls.toggle(opts[2].id);
      expect(await myOptions(), [opts[0].id, opts[2].id]..sort());
      await polls.toggle(opts[0].id);
      expect(await myOptions(), [opts[2].id]);
    });

    test(
      'retracting and voting again before the delete is sent cancels both',
      () async {
        await seed();
        await polls.vote(opts[0].id);
        await db
            .update(db.outbox)
            .write(const OutboxCompanion(sent: Value(true)));
        await db.delete(db.outbox).go(); // acknowledged
        await polls.unvote(opts[0].id);
        expect(await opSummary(db), [
          'delete:poll_votes/${voteIdFor(opts[0].id, 'me')}',
        ]);

        await polls.vote(opts[0].id);

        expect(
          await opSummary(db),
          isEmpty,
          reason: 'the server never saw the retraction',
        );
        expect(await myOptions(), [opts[0].id]);
      },
    );

    test('revoting after the retraction may have been sent revives the same id behind it', () async {
      await seed();
      await polls.vote(opts[0].id);
      await db.delete(db.outbox).go();
      await polls.unvote(opts[0].id);
      await db
          .update(db.outbox)
          .write(const OutboxCompanion(sent: Value(true)));

      await polls.vote(opts[0].id);

      final id = voteIdFor(opts[0].id, 'me');
      expect(await opSummary(db), [
        'delete:poll_votes/$id',
        'upsert:poll_votes/$id',
      ]);
      expect(await myOptions(), [opts[0].id]);
    });

    test('watching votes follows changes', () async {
      await seed();
      final first = polls.watchVotes(trip).first;
      expect(await first, isEmpty);
      await polls.vote(opts[0].id);
      expect(await polls.watchVotes(trip).first, hasLength(1));
    });
  });

  group('favorites', () {
    test(
      'toggle stars and unstars, queueing the creation and the deletion',
      () async {
        expect(await favorites.toggle('mountain', 'beidawu'), isTrue);
        expect(await favorites.isFavorite('mountain', 'beidawu'), isTrue);
        final op = (await db.select(db.outbox).get()).single;
        expect(patchOf(op), {'kind': 'mountain', 'target_id': 'beidawu'});
        expect(op.isCreate, isTrue);

        await db
            .update(db.outbox)
            .write(const OutboxCompanion(sent: Value(true)));
        expect(await favorites.toggle('mountain', 'beidawu'), isFalse);
        expect(await favorites.isFavorite('mountain', 'beidawu'), isFalse);
        expect(await opSummary(db), [startsWith('delete:favorites/')]);
      },
    );

    test(
      'duplicates from two devices read as one and are removed together',
      () async {
        await db
            .into(db.favorites)
            .insert(
              FavoritesCompanion.insert(
                id: 'a',
                kind: 'mountain',
                targetId: 'x',
              ),
            );
        await db
            .into(db.favorites)
            .insert(
              FavoritesCompanion.insert(
                id: 'b',
                kind: 'mountain',
                targetId: 'x',
              ),
            );
        await db
            .into(db.favorites)
            .insert(
              FavoritesCompanion.insert(
                id: 'c',
                kind: 'mountain',
                targetId: 'y',
              ),
            );
        expect(await favorites.watchTargets('mountain').first, ['x', 'y']);

        expect(await favorites.toggle('mountain', 'x'), isFalse);
        expect(await db.select(db.favorites).get(), hasLength(1));
        expect(await opSummary(db), [
          'delete:favorites/a',
          'delete:favorites/b',
        ]);
      },
    );

    test('watch tells whether one item is starred', () async {
      expect(await favorites.watch('mountain', 'x').first, isFalse);
      await favorites.toggle('mountain', 'x');
      expect(await favorites.watch('mountain', 'x').first, isTrue);
    });
  });
}
