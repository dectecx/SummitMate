import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/widgets.dart';

import '../domain/offline_regions.dart';
import 'download_updates.dart';
import 'offline_tile_store.dart';
import 'tile_cache.dart';
import 'tile_downloader.dart';

/// Downloads region tiles with the system's background transfer service (iOS URLSession, Android WorkManager),
/// so a download keeps going when the app is in the background. What is on disk is the truth: a retry, or the app
/// coming back, only fetches the tiles that are missing and never queues one that is already in flight.
class BackgroundTileDownloader implements TileDownloader {
  BackgroundTileDownloader(this._store);
  final OfflineTileStore _store;

  static String _group(String regionId) => 'offline-$regionId';
  static String _taskId(String regionId, TileId t) =>
      '$regionId/${t.z}/${t.x}/${t.y}';

  /// Call once at startup: limits how many tiles are fetched at the same time (kind to a public government
  /// server) and processes what happened while the app was suspended.
  static Future<void> configure() async {
    await FileDownloader().configure(
      globalConfig: [(Config.holdingQueue, (4, 4, 4))],
    );
    await FileDownloader().resumeFromBackground();
    WidgetsBinding.instance.addObserver(
      _ResumeHook(),
    ); // catches up on what happened while the app was suspended
  }

  @override
  Stream<DownloadUpdate> download(OfflineRegionDef region) async* {
    final downloader = FileDownloader();
    final group = _group(region.id);
    final store = _store;
    store.register(region.id);
    const urlTemplate = nlscTileUrl;
    final tiles = tilesFor(
      region.bounds,
      region.minZoom,
      region.maxZoom,
    ).toList();
    final inFlight = {
      for (final t in await downloader.allTasks(group: group)) t.taskId,
    };

    final remaining = <String>{}; // tiles whose file is not there yet
    final toQueue = <Task>[];
    var bytes = 0.0;
    for (final t in tiles) {
      final id = _taskId(region.id, t);
      final file = store.tileFile(region.id, t.z, t.x, t.y);
      if (file.existsSync()) {
        bytes += file.lengthSync();
        continue;
      }
      remaining.add(id);
      if (!inFlight.contains(id)) {
        toQueue.add(
          DownloadTask(
            taskId: id,
            url: urlTemplate
                .replaceAll('{z}', '${t.z}')
                .replaceAll('{y}', '${t.y}')
                .replaceAll('{x}', '${t.x}'),
            baseDirectory: BaseDirectory.applicationSupport,
            directory: store.tileDirectory(region.id, t.z, t.x),
            filename: OfflineTileStore.tileFilename(t.y),
            group: group,
            updates: Updates.status,
            retries: 2,
            headers: {'User-Agent': appPackageName},
          ),
        );
      }
    }

    final out = StreamController<DownloadUpdate>();
    var failed = 0;
    void emit() {
      if (!out.isClosed) {
        out.add(DownloadUpdate(done: tiles.length - remaining.length, total: tiles.length, bytes: bytes));
      }
    }

    final sub = DownloadUpdates.stream.listen((u) async {
      if (u is! TaskStatusUpdate ||
          u.task.group != group ||
          !u.status.isFinalState) {
        return;
      }
      if (u.status == TaskStatus.complete) {
        final file = File(await u.task.filePath());
        if (file.existsSync()) bytes += file.lengthSync();
      } else if (u.status != TaskStatus.canceled) {
        failed++;
      }
      if (remaining.remove(u.task.taskId)) emit();
      if (remaining.isEmpty && !out.isClosed) await out.close();
    });
    try {
      emit();
      if (remaining.isEmpty) {
        await out.close();
      } else if (toQueue.isNotEmpty) {
        await downloader.enqueueAll(toQueue);
      }
      yield* out.stream;
    } finally {
      await sub.cancel();
      if (!out.isClosed) await out.close();
    }
    if (failed > 0) throw StateError('$failed 張圖磚下載失敗');
  }

  @override
  Future<bool> isRunning(String regionId) async =>
      (await FileDownloader().allTasks(group: _group(regionId))).isNotEmpty;

  @override
  Future<void> cancel(String regionId) async {
    final tasks = await FileDownloader().allTasks(group: _group(regionId));
    await FileDownloader().cancelTasksWithIds([
      for (final t in tasks) t.taskId,
    ]);
  }

  @override
  Future<void> deleteTiles(String regionId) async {
    await cancel(regionId);
    await _store.delete(regionId);
  }
}

class _ResumeHook with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FileDownloader().resumeFromBackground();
    }
  }
}
