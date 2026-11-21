// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'local_store.dart';
import 'pull_applier.dart';
import 'sync_api.dart';
import 'sync_entity.dart';

/// Tells the engine whether syncing is currently possible (signed in, session valid).
abstract interface class SyncGate {
  bool get canSync;
}

enum SyncOutcome {
  /// Everything pushed and pulled.
  success,

  /// Not signed in (guest) or session needs re-login; nothing was attempted.
  skipped,

  /// A transient failure; try again after [SyncEngine.retryDelay].
  retryLater,

  /// The server rejected our credentials; the auth layer must ask the user to sign in again.
  needsReauth,
}

/// Pushes the outbox, then pulls server changes. One instance per database; calls made while a
/// run is in progress share that run.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncApi api,
    required SyncGate gate,
    DateTime Function()? now,
    this.batchSize = 50,
    this.pullLimit = 200,
    this.cursorOverlap = const Duration(seconds: 5),
    this.onAuthFailure,
  }) : _db = db,
       _api = api,
       _gate = gate,
       _now = now ?? DateTime.now,
       _store = LocalStore(db),
       _applier = PullApplier(db);

  final AppDatabase _db;
  final SyncApi _api;
  final SyncGate _gate;
  final DateTime Function() _now;
  final LocalStore _store;
  final PullApplier _applier;

  final int batchSize;
  final int pullLimit;
  final Duration cursorOverlap;
  final void Function()? onAuthFailure;

  Future<SyncOutcome>? _inFlight;
  final _running = StreamController<bool>.broadcast();
  int _failures = 0;

  /// Emits true when a run starts and false when it ends.
  Stream<bool> get running => _running.stream;
  bool get isRunning => _inFlight != null;

  /// Consecutive failed runs; reset by a successful one.
  int get consecutiveFailures => _failures;

  /// 1s, 2s, 4s ... capped at 5 minutes.
  Duration get retryDelay => backoffFor(_failures);

  static Duration backoffFor(int failures) {
    if (failures <= 0) return Duration.zero;
    return Duration(seconds: min(300, pow(2, failures - 1).toInt()));
  }

  /// Forgets the backoff (network came back, user pulled to refresh).
  void resetBackoff() => _failures = 0;

  Future<SyncOutcome> sync() => _inFlight ??= _run().whenComplete(() {
    _inFlight = null;
    _running.add(false);
  });

  Future<SyncOutcome> _run() async {
    if (!_gate.canSync) return SyncOutcome.skipped;
    _running.add(true);
    try {
      await _push();
      await _pull();
      await _db.update(_db.appMeta).write(AppMetaCompanion(lastSyncedAt: Value(_now())));
      _failures = 0;
      return SyncOutcome.success;
    } on SyncAuthException {
      onAuthFailure?.call();
      return SyncOutcome.needsReauth;
    } on SyncNetworkException {
      _failures++;
      return SyncOutcome.retryLater;
    } on SyncServerException catch (e) {
      _failures++;
      if (!e.retryable) rethrow;
      return SyncOutcome.retryLater;
    }
  }

  // ---------------------------------------------------------------- push

  Future<void> _push() async {
    for (var batch = 0; batch < 200; batch++) {
      if (!_gate.canSync) return;
      final ops =
          await (_db.select(_db.outbox)
                ..where((o) => o.state.equals('pending'))
                ..orderBy([(o) => OrderingTerm.asc(o.seq)])
                ..limit(batchSize))
              .get();
      if (ops.isEmpty) return;

      // The server may apply the batch even if we never see the response.
      await (_db.update(_db.outbox)..where((o) => o.seq.isIn(ops.map((o) => o.seq)))).write(const OutboxCompanion(sent: Value(true)));

      final List<PushOpResult> results;
      try {
        results = await _api.push([
          for (final op in ops)
            PushRequestOp(
              opId: op.opId,
              entity: op.entity,
              entityId: op.entityId,
              type: op.type,
              patch: op.type == 'upsert' ? (jsonDecode(op.patch) as Map).cast<String, Object?>() : null,
            ),
        ]);
      } on SyncServerException catch (e) {
        if (!e.retryable) await _failBatch(ops, 'server rejected the request (${e.statusCode}) ${e.message}');
        rethrow;
      } on SyncNetworkException catch (e) {
        await _bumpAttempts(ops, e.message);
        rethrow;
      }
      if (results.length != ops.length) {
        throw SyncServerException(502, message: 'expected ${ops.length} results, got ${results.length}');
      }
      await _db.transaction(() async {
        for (final r in results) {
          await _handleResult(r);
        }
      });
    }
  }

  Future<void> _handleResult(PushOpResult r) async {
    final op = await (_db.select(_db.outbox)..where((o) => o.opId.equals(r.opId))).getSingleOrNull();
    // null: the op was edited (new op id) or removed while the request was in flight.
    final e = syncEntityByName[op?.entity ?? ''];

    switch (r.status) {
      case PushStatus.applied:
        if (op != null) await _remove(op.seq);
        final row = r.row;
        if (op != null && e != null && op.type == 'upsert' && row != null) {
          if (!await _hasPendingDelete(e.name, op.entityId)) {
            await _store.upsertFromServer(e, row);
            await _applier.overlayPending(e, op.entityId);
          }
        }
      case PushStatus.gone:
        if (op != null) {
          await _remove(op.seq);
          if (op.type == 'upsert') await _store.deleteRow(op.entity, op.entityId);
        }
      case PushStatus.forbidden:
      case PushStatus.invalid:
        if (op != null) {
          await (_db.update(_db.outbox)..where((o) => o.seq.equals(op.seq))).write(
            OutboxCompanion(
              state: const Value('failed'),
              attempts: Value(op.attempts + 1),
              lastError: Value('${r.status.name}: ${r.message ?? ''}'),
            ),
          );
        }
    }
  }

  Future<void> _remove(int seq) => (_db.delete(_db.outbox)..where((o) => o.seq.equals(seq))).go();

  Future<bool> _hasPendingDelete(String entity, String id) async =>
      (await (_db.select(_db.outbox)..where((o) => o.entity.equals(entity) & o.entityId.equals(id) & o.type.equals('delete'))).get()).isNotEmpty;

  Future<void> _bumpAttempts(List<OutboxOp> ops, String error) async {
    for (final op in ops) {
      await (_db.update(_db.outbox)..where((o) => o.seq.equals(op.seq))).write(
        OutboxCompanion(attempts: Value(op.attempts + 1), lastError: Value(error)),
      );
    }
  }

  Future<void> _failBatch(List<OutboxOp> ops, String error) async {
    for (final op in ops) {
      await (_db.update(_db.outbox)..where((o) => o.seq.equals(op.seq))).write(
        OutboxCompanion(state: const Value('failed'), attempts: Value(op.attempts + 1), lastError: Value(error)),
      );
    }
  }

  // ---------------------------------------------------------------- pull

  Future<void> _pull() async {
    final meta = await (_db.select(_db.appMeta)..where((m) => m.id.equals(1))).getSingle();
    String? since = _withOverlay(meta.syncCursor);
    for (var page = 0; page < 1000; page++) {
      if (!_gate.canSync) return;
      final result = await _api.pull(since: since, limit: pullLimit);
      await _applier.applyPage(result);
      if (!result.hasMore) return;
      // Guard against a server that cannot make progress.
      if (result.nextSince == since) return;
      since = result.nextSince;
    }
  }

  /// The first request of a run starts a little before the stored cursor, because commit
  /// order can differ slightly from timestamp order. Applying rows twice is harmless.
  String? _withOverlay(String? cursor) {
    if (cursor == null) return null;
    final t = DateTime.tryParse(cursor);
    if (t == null) return null;
    return t.subtract(cursorOverlap).toUtc().toIso8601String();
  }

  Future<void> dispose() => _running.close();
}
