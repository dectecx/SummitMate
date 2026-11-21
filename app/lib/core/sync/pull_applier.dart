import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'local_store.dart';
import 'sync_api.dart';
import 'sync_entity.dart';

/// Applies a pulled page to the local database in one transaction.
///
/// Rules (docs/architecture/FRONTEND_DATA.md §4):
///  1. rows whose entity has a pending delete are skipped (no resurrection);
///  2. tombstones hard-delete the local row; the caller's own `trip_members` tombstone removes the trip;
///  3. other rows are upserted, then pending local patches are re-applied on top;
///  4. rows whose parent is missing locally are skipped;
///  5. the sync cursor is advanced in the same transaction.
class PullApplier {
  PullApplier(this._db) : _store = LocalStore(_db);
  final AppDatabase _db;
  final LocalStore _store;

  Future<void> applyPage(PullPage page) => _db.transaction(() async {
    final accountId = await _accountId();
    for (final e in syncEntities) {
      for (final row in page.changes[e.name] ?? const <Map<String, Object?>>[]) {
        await _applyRow(e, row, accountId);
      }
    }
    await _db.update(_db.appMeta).write(AppMetaCompanion(syncCursor: Value(page.nextSince)));
  });

  Future<String?> _accountId() async => (await (_db.select(_db.appMeta)..where((m) => m.id.equals(1))).getSingleOrNull())?.accountId;

  Future<void> _applyRow(SyncEntity e, Map<String, Object?> row, String? accountId) async {
    final id = row['id'];
    if (id is! String) return;
    if (await _hasOp(e.name, id, 'delete')) return;

    if (row['deleted_at'] != null) {
      if (e.name == 'trip_members' && row['user_id'] == accountId && accountId != null) {
        final tripId = row['trip_id'];
        if (tripId is String) await _store.deleteRow('trips', tripId);
        return;
      }
      await _store.deleteRow(e.name, id);
      return;
    }

    for (final p in e.parents) {
      final parentId = row[p.column];
      if (parentId is! String || !await _store.exists(p.table, parentId)) return;
    }
    await _store.upsertFromServer(e, row);
    await overlayPending(e, id);
  }

  Future<bool> _hasOp(String entity, String id, String type) async {
    final rows = await (_db.select(_db.outbox)
          ..where((o) => o.entity.equals(entity) & o.entityId.equals(id) & o.type.equals(type))
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  /// Re-applies the entity's pending (not yet acknowledged) local edits on top of server data.
  Future<void> overlayPending(SyncEntity e, String id) async {
    final ops = await (_db.select(_db.outbox)
          ..where((o) => o.entity.equals(e.name) & o.entityId.equals(id) & o.type.equals('upsert'))
          ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
        .get();
    for (final op in ops) {
      await _store.applyPatch(e, id, (jsonDecode(op.patch) as Map).cast<String, Object?>());
    }
  }
}
