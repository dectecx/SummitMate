// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/collab_logic.dart';

/// The message board of a trip. Offline-first: the row and its upload are written in one transaction.
///
/// Authorship: `user_id` is never uploaded (the server sets it to the actor). Locally it holds the
/// signed-in account's id, or null when written as a guest; sign-in fills it in.
class MessageRepository {
  MessageRepository(
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

  /// Every message of the trip, oldest first; threading is done by `buildThreads`.
  Stream<List<TripMessage>> watch(String tripId) =>
      (_db.select(_db.tripMessages)
            ..where((m) => m.tripId.equals(tripId))
            ..orderBy([
              (m) => OrderingTerm.asc(m.createdAt),
              (m) => OrderingTerm.asc(m.id),
            ]))
          .watch();

  /// Posts [body]; with [parentId] it is a reply, which must target a top-level message.
  Future<String> add(String tripId, String body, {String? parentId}) async {
    final error = validateMessageBody(body);
    if (error != null) throw ArgumentError(error);
    final text = body.trim();
    final id = _uuid.v7();
    await _db.transaction(() async {
      if (parentId != null) {
        final parent = await (_db.select(
          _db.tripMessages,
        )..where((m) => m.id.equals(parentId))).getSingleOrNull();
        if (parent == null || parent.tripId != tripId) {
          throw ArgumentError('the message to reply to is not in this trip');
        }
        if (!canReplyTo(parent)) throw ArgumentError('只能回覆最上層的留言');
      }
      await _db
          .into(_db.tripMessages)
          .insert(
            TripMessagesCompanion.insert(
              id: id,
              tripId: tripId,
              userId: Value(_myId()),
              parentId: Value(parentId),
              body: text,
              createdAt: _now(),
            ),
          );
      await _outbox.upsert('trip_messages', id, {
        'trip_id': tripId,
        'parent_id': ?parentId,
        'body': text,
      }, isCreate: true);
    });
    return id;
  }

  /// Changes the text of a message (the server only accepts this from its author).
  Future<void> edit(String id, String body) async {
    final error = validateMessageBody(body);
    if (error != null) throw ArgumentError(error);
    final text = body.trim();
    await _db.transaction(() async {
      await (_db.update(_db.tripMessages)..where((m) => m.id.equals(id))).write(
        TripMessagesCompanion(body: Value(text)),
      );
      await _outbox.upsert('trip_messages', id, {'body': text});
    });
  }

  /// Replies are kept; they show as top-level messages once their parent is gone.
  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('trip_messages', id);
    await (_db.delete(_db.tripMessages)..where((m) => m.id.equals(id))).go();
  });
}
