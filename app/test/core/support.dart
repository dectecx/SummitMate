import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_api.dart';
import 'package:summitmate/core/sync/sync_engine.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

AppDatabase memoryDb() {
  // Tests that simulate two devices open two databases on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

class FakeGate implements SyncGate {
  FakeGate([this.canSync = true]);
  @override
  bool canSync;
}

/// A tiny in-memory server speaking the sync protocol: idempotent by op_id, field-level merge,
/// tombstones, time-cursor pull. It also lets tests simulate other devices and failures.
class FakeServer implements SyncApi {
  FakeServer({this.userId = 'u1'});

  final String userId;
  final Map<String, Map<String, Map<String, Object?>>> rows = {};
  final Map<String, PushOpResult> processed = {};
  final List<List<PushRequestOp>> pushLog = [];
  final List<String?> pullSinceLog = [];
  DateTime clock = DateTime.utc(2026, 1, 1, 12);
  int pullCalls = 0;

  /// Thrown (once) by the next push/pull if set.
  Object? failNextPush;
  Object? failNextPull;

  /// Called after the server applied a push but before the client sees the response.
  Future<void> Function()? onPushApplied;

  /// op ids / entity names that must be rejected as forbidden.
  final Set<String> forbiddenEntities = {};

  String _tick() {
    clock = clock.add(const Duration(seconds: 1));
    return clock.toIso8601String();
  }

  Map<String, Object?> _row(String entity, String id) => rows.putIfAbsent(entity, () => {}).putIfAbsent(id, () => {'id': id, 'deleted_at': null});

  /// Simulates an edit made by another device.
  void serverEdit(String entity, String id, Map<String, Object?> fields) {
    final r = _row(entity, id);
    r.addAll(fields);
    r['updated_at'] = _tick();
  }

  void serverDelete(String entity, String id) {
    final r = _row(entity, id);
    r['deleted_at'] = _tick();
    r['updated_at'] = r['deleted_at'];
  }

  Map<String, Object?>? row(String entity, String id) => rows[entity]?[id];

  @override
  Future<List<PushOpResult>> push(List<PushRequestOp> ops) async {
    pushLog.add(ops);
    final results = <PushOpResult>[];
    for (final op in ops) {
      final prev = processed[op.opId];
      if (prev != null) {
        results.add(prev);
        continue;
      }
      PushOpResult res;
      if (forbiddenEntities.contains(op.entity)) {
        res = PushOpResult(opId: op.opId, status: PushStatus.forbidden, message: 'nope');
      } else if (op.type == 'delete') {
        final existing = rows[op.entity]?[op.entityId];
        if (existing == null || existing['deleted_at'] != null) {
          res = PushOpResult(opId: op.opId, status: PushStatus.gone);
        } else {
          existing['deleted_at'] = _tick();
          existing['updated_at'] = existing['deleted_at'];
          res = PushOpResult(opId: op.opId, status: PushStatus.applied, row: Map.of(existing));
        }
      } else {
        final existing = rows[op.entity]?[op.entityId];
        if (existing != null && existing['deleted_at'] != null) {
          res = PushOpResult(opId: op.opId, status: PushStatus.gone);
        } else {
          final r = _row(op.entity, op.entityId);
          if (op.entity == 'trips') r.putIfAbsent('owner_id', () => userId);
          r.addAll(op.patch ?? const {});
          r['updated_at'] = _tick();
          res = PushOpResult(opId: op.opId, status: PushStatus.applied, row: Map.of(r));
        }
      }
      processed[op.opId] = res;
      results.add(res);
    }
    final hook = onPushApplied;
    onPushApplied = null;
    if (hook != null) await hook();
    final failure = failNextPush;
    if (failure != null) {
      failNextPush = null;
      // The request reached the server (it applied the ops) but the response was lost.
      throw failure;
    }
    return results;
  }

  @override
  Future<PullPage> pull({String? since, int limit = 200}) async {
    pullCalls++;
    pullSinceLog.add(since);
    final failure = failNextPull;
    if (failure != null) {
      failNextPull = null;
      throw failure;
    }
    final floor = since == null ? DateTime.utc(1970) : DateTime.parse(since);
    final changes = <String, List<Map<String, Object?>>>{};
    var hasMore = false;
    DateTime? cut;
    for (final e in syncEntities) {
      final list = (rows[e.name]?.values ?? const <Map<String, Object?>>[])
          .where((r) => r['updated_at'] != null && DateTime.parse(r['updated_at'] as String).isAfter(floor))
          .toList()
        ..sort((a, b) => (a['updated_at'] as String).compareTo(b['updated_at'] as String));
      final page = list.take(limit).map((r) => Map<String, Object?>.of(r)).toList();
      if (page.isNotEmpty) changes[e.name] = page;
      if (list.length > limit) {
        hasMore = true;
        final last = DateTime.parse(page.last['updated_at'] as String);
        if (cut == null || last.isBefore(cut)) cut = last;
      }
    }
    final now = clock.toIso8601String();
    return PullPage(serverTime: now, nextSince: (cut ?? clock).toIso8601String(), hasMore: hasMore, changes: changes);
  }
}

Map<String, Object?> tripRow(String id, {String name = 'Trip', String? ownerId, String start = '2026-05-01'}) => {
  'id': id,
  'owner_id': ownerId,
  'name': name,
  'description': '',
  'start_date': start,
  'end_date': null,
  'cover_image': null,
};

Map<String, Object?> itemRow(String id, String tripId, {String name = 'Item'}) => {
  'id': id,
  'trip_id': tripId,
  'day_index': 0,
  'name': name,
  'est_minutes': null,
  'altitude': 0,
  'distance': 0.0,
  'lat': null,
  'lng': null,
  'note': '',
  'checked_in_at': null,
};

Map<String, Object?> gearRow(String id, String tripId, {String name = 'Gear'}) => {
  'id': id,
  'trip_id': tripId,
  'name': name,
  'weight': 0.5,
  'category': 'other',
  'quantity': 1,
  'is_checked': false,
  'sort_order': 0,
};

/// What a repository does for a local creation: write the row and queue the upload atomically.
Future<void> localCreate(AppDatabase db, OutboxWriter w, SyncEntity e, Map<String, Object?> row) async {
  final store = LocalStore(db);
  await db.transaction(() async {
    await store.upsertFromServer(e, row);
    final patch = {for (final k in e.columns.keys) if (row.containsKey(k) && k != 'owner_id') k: row[k]};
    await w.upsert(e.name, row['id']! as String, patch, isCreate: true);
  });
}

Future<void> localEdit(AppDatabase db, OutboxWriter w, SyncEntity e, String id, Map<String, Object?> changes) async {
  final store = LocalStore(db);
  await db.transaction(() async {
    await store.applyPatch(e, id, changes);
    await w.upsert(e.name, id, changes);
  });
}

Future<void> localDelete(AppDatabase db, OutboxWriter w, SyncEntity e, String id) async {
  final store = LocalStore(db);
  await db.transaction(() async {
    await w.delete(e.name, id); // before removing the row
    await store.deleteRow(e.name, id);
  });
}

Future<List<String>> opSummary(AppDatabase db) async {
  final ops = await db.select(db.outbox).get();
  ops.sort((a, b) => a.seq.compareTo(b.seq));
  return [for (final o in ops) '${o.type}:${o.entity}/${o.entityId}${o.state == 'failed' ? ':failed' : ''}'];
}

Future<List<Map<String, Object?>>> select(AppDatabase db, String sql) async =>
    [for (final r in await db.customSelect(sql).get()) r.data];

Map<String, Object?> patchOf(dynamic op) => (jsonDecode(op.patch as String) as Map).cast<String, Object?>();
