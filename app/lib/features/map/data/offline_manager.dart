import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/offline_regions.dart';
import 'tile_downloader.dart';

/// States of a region row in `offline_regions`.
abstract final class OfflineState {
  static const queued = 'queued';
  static const downloading = 'downloading';
  static const done = 'done';
  static const failed = 'failed';
  static const interrupted = 'interrupted';
}

/// Runs offline map downloads one at a time, in the order they were requested, and records their
/// state in the database so the screen (and the person coming back later) always sees the truth.
///
/// One failing download never stops the others: it is marked failed and the queue moves on.
class OfflineMapsManager {
  OfflineMapsManager(this._db, this._downloader, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final TileDownloader _downloader;
  final DateTime Function() _now;

  final _queue = <String>[];
  String? _active;
  final _cancelled = <String>{};

  /// All region rows (the screen combines them with the region definitions).
  Stream<List<OfflineRegion>> watch() => _db.select(_db.offlineRegions).watch();

  Future<OfflineRegion?> _row(String id) => (_db.select(_db.offlineRegions)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Call once at startup: anything that was queued or running when the app last stopped was cut off.
  ///
  /// Downloads the system kept running in the background are picked up again; the rest are marked interrupted
  /// (the person can resume them).
  Future<void> recover() async {
    final cut = await (_db.select(_db.offlineRegions)..where((r) => r.state.isIn([OfflineState.queued, OfflineState.downloading]))).get();
    for (final r in cut) {
      if (await _downloader.isRunning(r.id)) {
        _queue.add(r.id);
      } else {
        await _update(r.id, state: OfflineState.interrupted);
      }
    }
    unawaited(_pump());
  }

  /// Queues a download (or resumes a failed or interrupted one). Already downloaded or queued regions are left alone.
  Future<void> start(String id) async {
    final def = offlineRegionById(id);
    if (def == null) return;
    final row = await _row(id);
    if (row != null && (row.state == OfflineState.done || row.state == OfflineState.queued || row.state == OfflineState.downloading)) return;
    await _db.into(_db.offlineRegions).insertOnConflictUpdate(
      OfflineRegionsCompanion.insert(
        id: id,
        state: OfflineState.queued,
        tilesDone: Value(row?.tilesDone ?? 0),
        tilesTotal: Value(row?.tilesTotal ?? def.estimatedTiles),
        bytes: Value(row?.bytes ?? 0),
        updatedAt: _now(),
      ),
    );
    _queue.add(id);
    unawaited(_pump());
  }

  /// Stops a queued or running download and forgets it (tiles stored so far are removed).
  Future<void> cancel(String id) async {
    _queue.remove(id);
    if (_active == id) {
      _cancelled.add(id);
      await _downloader.cancel(id);
      return; // the running loop removes the row when its stream ends
    }
    await _remove(id);
  }

  /// Deletes a downloaded (or failed) region and its tiles.
  Future<void> delete(String id) async {
    if (_active == id) return cancel(id);
    _queue.remove(id);
    await _remove(id);
  }

  Future<void> _remove(String id) async {
    await _downloader.deleteTiles(id);
    await (_db.delete(_db.offlineRegions)..where((r) => r.id.equals(id))).go();
  }

  Future<void> _pump() async {
    if (_active != null || _queue.isEmpty) return;
    final id = _queue.removeAt(0);
    _active = id;
    try {
      await _run(id);
    } finally {
      _active = null;
      unawaited(_pump());
    }
  }

  Future<void> _run(String id) async {
    final def = offlineRegionById(id);
    if (def == null) return;
    await _update(id, state: OfflineState.downloading, error: const Value(null));
    DownloadUpdate? last;
    try {
      await for (final u in _downloader.download(def)) {
        last = u;
        await _update(id, tilesDone: u.done, tilesTotal: u.total, bytes: u.bytes);
      }
      if (_cancelled.remove(id)) {
        await _remove(id);
      } else {
        await _update(id, state: OfflineState.done, tilesDone: last?.total, tilesTotal: last?.total, error: const Value(null));
      }
    } on Object catch (e) {
      if (_cancelled.remove(id)) {
        await _remove(id);
      } else {
        await _update(id, state: OfflineState.failed, error: Value('$e'));
      }
    }
  }

  Future<void> _update(String id, {String? state, int? tilesDone, int? tilesTotal, double? bytes, Value<String?> error = const Value.absent()}) {
    return (_db.update(_db.offlineRegions)..where((r) => r.id.equals(id))).write(
      OfflineRegionsCompanion(
        state: Value.absentIfNull(state),
        tilesDone: Value.absentIfNull(tilesDone),
        tilesTotal: Value.absentIfNull(tilesTotal),
        bytes: Value.absentIfNull(bytes),
        error: error,
        updatedAt: Value(_now()),
      ),
    );
  }
}
