// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import 'local_store.dart';
import 'sync_entity.dart';

/// The only way repositories enqueue sync work. Every method runs inside a transaction
/// (nestable: call it from within the repository's own `db.transaction`).
///
/// Call [delete] **before** removing the local row: it needs the row to find the owning
/// trip and the children whose pending operations must be dropped.
class OutboxWriter {
  OutboxWriter(this._db, {Uuid uuid = const Uuid(), DateTime Function()? now})
    : _store = LocalStore(_db),
      _uuid = uuid,
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final LocalStore _store;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Queues an upsert of [patch] (only the changed fields, or every field plus `trip_id`
  /// for a creation) for entity [entity] with id [id].
  Future<void> upsert(String entity, String id, Map<String, Object?> patch, {bool isCreate = false}) async {
    final e = _entity(entity);
    final unknown = patch.keys.where((k) => !e.columns.containsKey(k));
    if (unknown.isNotEmpty) throw ArgumentError('unknown fields for $entity: ${unknown.join(', ')}');
    final json = {for (final entry in patch.entries) entry.key: toJson(entry.value)};

    await _db.transaction(() async {
      if (await _belongsToSample(entity, id, patch)) return;

      final pendingDelete = await _find(entity, id, 'delete');
      if (pendingDelete != null) throw StateError('cannot edit $entity/$id: it is queued for deletion');

      final existing = await _find(entity, id, 'upsert');
      if (existing == null) {
        await _insert(entity, id, 'upsert', patch: json, isCreate: isCreate);
        return;
      }
      final merged = {...(jsonDecode(existing.patch) as Map<String, Object?>), ...json};
      await (_db.update(_db.outbox)..where((o) => o.seq.equals(existing.seq))).write(
        OutboxCompanion(
          patch: Value(jsonEncode(merged)),
          // The server may already hold the old content under the old op id and would replay
          // its cached result for it, so changed content needs a new idempotency key.
          opId: existing.sent ? Value(_uuid.v4()) : const Value.absent(),
          // Editing a failed op gives it another chance.
          state: const Value('pending'),
          attempts: const Value(0),
          lastError: const Value(null),
        ),
      );
    });
  }

  /// Queues deletion of [entity]/[id]. Deleting a trip drops every pending operation of its
  /// content; deleting a meal plan day also queues deletion of its meal items.
  Future<void> delete(String entity, String id) async {
    _entity(entity);
    await _db.transaction(() async {
      if (await _belongsToSample(entity, id, const {})) return;
      switch (entity) {
        case 'trips':
          for (final child in syncEntities.where((e) => e.name != 'trips')) {
            for (final childId in await _store.childIds(child.name, 'trip_id', id)) {
              await _removeOps(child.name, childId);
            }
          }
          await _deleteOne('trips', id);
        case 'meal_plan_days':
          for (final itemId in await _store.childIds('meal_items', 'meal_plan_day_id', id)) {
            await _deleteOne('meal_items', itemId);
          }
          await _deleteOne('meal_plan_days', id);
        default:
          await _deleteOne(entity, id);
      }
    });
  }

  /// Drops every pending operation of a trip's content (not the trip itself). Used when the person
  /// leaves a trip: whatever they had queued for it can no longer be accepted by the server.
  Future<void> dropTripWork(String tripId) => _db.transaction(() async {
    for (final child in syncEntities.where((e) => e.name != 'trips')) {
      for (final childId in await _store.childIds(child.name, 'trip_id', tripId)) {
        await _removeOps(child.name, childId);
      }
    }
    await _removeOps('trips', tripId);
  });

  /// Gives up on a failed op. The local data is made consistent with that choice:
  /// a failed creation is removed locally (with its pending content); a failed edit or delete
  /// resets the sync cursor so the next sync re-downloads the server's version.
  Future<void> discardFailed(int seq) => _db.transaction(() async {
    final op = await (_db.select(_db.outbox)..where((o) => o.seq.equals(seq))).getSingleOrNull();
    if (op == null) return;
    if (op.type == 'upsert' && op.isCreate) {
      if (op.entity == 'trips') {
        for (final child in syncEntities.where((e) => e.name != 'trips')) {
          for (final childId in await _store.childIds(child.name, 'trip_id', op.entityId)) {
            await _removeOps(child.name, childId);
          }
        }
      }
      await _removeOps(op.entity, op.entityId);
      await _store.deleteRow(op.entity, op.entityId);
    } else {
      await (_db.delete(_db.outbox)..where((o) => o.seq.equals(seq))).go();
      await (_db.update(_db.appMeta)).write(const AppMetaCompanion(syncCursor: Value(null)));
    }
  });

  /// Puts a failed op back in the queue.
  Future<void> retryFailed(int seq) => (_db.update(_db.outbox)..where((o) => o.seq.equals(seq))).write(
    const OutboxCompanion(state: Value('pending'), attempts: Value(0), lastError: Value(null)),
  );

  // ---------------------------------------------------------------- internals

  SyncEntity _entity(String name) => syncEntityByName[name] ?? (throw ArgumentError('unknown entity $name'));

  Future<void> _deleteOne(String entity, String id) async {
    if (await _find(entity, id, 'delete') != null) return;
    final upsert = await _find(entity, id, 'upsert');
    if (upsert != null) {
      await (_db.delete(_db.outbox)..where((o) => o.seq.equals(upsert.seq))).go();
      // Never reached the server: nothing to tell it.
      if (upsert.isCreate && !upsert.sent) return;
    }
    await _insert(entity, id, 'delete');
  }

  Future<void> _removeOps(String entity, String id) =>
      (_db.delete(_db.outbox)..where((o) => o.entity.equals(entity) & o.entityId.equals(id))).go();

  Future<OutboxOp?> _find(String entity, String id, String type) => (_db.select(
    _db.outbox,
  )..where((o) => o.entity.equals(entity) & o.entityId.equals(id) & o.type.equals(type))).getSingleOrNull();

  Future<void> _insert(String entity, String id, String type, {Map<String, Object?>? patch, bool isCreate = false}) =>
      _db.into(_db.outbox).insert(
        OutboxCompanion.insert(
          opId: _uuid.v4(),
          entity: entity,
          entityId: id,
          type: type,
          patch: Value(jsonEncode(patch ?? const {})),
          isCreate: Value(isCreate),
          createdAt: _now(),
        ),
      );

  /// True when the entity lives in the bundled sample trip, which never syncs.
  Future<bool> _belongsToSample(String entity, String id, Map<String, Object?> patch) async {
    final tripId = entity == 'trips' ? id : (patch['trip_id'] as String? ?? await _store.tripIdOf(entity, id));
    return tripId != null && await _store.isSampleTrip(tripId);
  }
}
