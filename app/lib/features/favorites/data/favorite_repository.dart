// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// What can be starred. The server accepts the same set.
class FavoriteKind {
  static const mountain = 'mountain';
  static const groupEvent = 'group_event';
}

/// The person's starred items. Offline-first: the row and its upload are written in one transaction.
/// The same item may exist twice (two devices starred it before syncing), so reads deduplicate by
/// (kind, target_id) and removing deletes every copy.
class FavoriteRepository {
  FavoriteRepository(this._db, this._outbox, {Uuid uuid = const Uuid()})
    : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  /// Target ids of [kind], in the order they were starred.
  Stream<List<String>> watchTargets(String kind) =>
      (_db.select(_db.favorites)
            ..where((f) => f.kind.equals(kind))
            ..orderBy([
              (f) => OrderingTerm.asc(f.id),
            ])) // ids are time-ordered (uuid v7)
          .watch()
          .map((rows) => {for (final r in rows) r.targetId}.toList());

  Stream<bool> watch(String kind, String targetId) =>
      watchTargets(kind).map((ids) => ids.contains(targetId));

  Future<bool> isFavorite(String kind, String targetId) async =>
      (await _rows(kind, targetId)).isNotEmpty;

  /// Stars or unstars the item. Returns true when it is a favorite afterwards.
  Future<bool> toggle(String kind, String targetId) => _db.transaction(
    () async {
      final rows = await _rows(kind, targetId);
      if (rows.isEmpty) {
        final id = _uuid.v7();
        await _db
            .into(_db.favorites)
            .insert(
              FavoritesCompanion.insert(id: id, kind: kind, targetId: targetId),
            );
        await _outbox.upsert('favorites', id, {
          'kind': kind,
          'target_id': targetId,
        }, isCreate: true);
        return true;
      }
      for (final r in rows) {
        await _outbox.delete('favorites', r.id);
        await (_db.delete(_db.favorites)..where((f) => f.id.equals(r.id))).go();
      }
      return false;
    },
  );

  Future<List<Favorite>> _rows(String kind, String targetId) => (_db.select(
    _db.favorites,
  )..where((f) => f.kind.equals(kind) & f.targetId.equals(targetId))).get();
}
