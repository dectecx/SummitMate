import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../../data/models/download_task.dart';
import 'offline_map_state.dart';

class OfflineMapCubit extends Cubit<OfflineMapState> {
  final FMTCStore _store = FMTCStore('osm_store');
  bool _isQueueProcessing = false;

  OfflineMapCubit() : super(OfflineMapInitial()) {
    _init();
  }

  Future<void> _init() async {
    String packageName = '';
    try {
      packageName = GetIt.instance<PackageInfo>().packageName;
    } catch (e) {
      // fallback or retry?
    }
    emit(OfflineMapLoaded(store: _store, packageName: packageName));
  }

  /// 初始化/確保 Store 存在
  Future<void> initStore() async {
    if (state is OfflineMapLoaded && (state as OfflineMapLoaded).isStoreReady) return;

    LogService.info('Initializing FMTC store "osm_store"...', source: 'OfflineMapCubit');

    try {
      await _store.manage.create();
      LogService.info('Store created/opened successfully.', source: 'OfflineMapCubit');
    } catch (e) {
      LogService.warning('Error creating store (ignoring if exists): $e', source: 'OfflineMapCubit');
    }

    if (state is OfflineMapLoaded) {
      emit((state as OfflineMapLoaded).copyWith(isStoreReady: true));
    } else {
      String packageName = '';
      try {
        packageName = GetIt.instance<PackageInfo>().packageName;
      } catch (_) {}
      emit(OfflineMapLoaded(store: _store, isStoreReady: true, packageName: packageName));
    }

    LogService.info('State set to ready.', source: 'OfflineMapCubit');
  }

  /// 下載指定區域
  ///
  /// [bounds] 下載範圍 (經緯度邊界)
  /// [minZoom] 最小縮放層級
  /// [maxZoom] 最大縮放層級
  /// [name] 任務名稱 (可選)
  /// [onProgress] 下載進度 Callback (可選)
  Future<void> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    String? name,
    Function(double progress)? onProgress, // 進度回調 (非必須，可透過狀態監聽)
  }) async {
    final hasConnection = await InternetConnectionChecker.createInstance().hasConnection;
    LogService.info(
      'Download requested. Connectivity: ${hasConnection ? "Online" : "Offline"}',
      source: 'OfflineMapCubit',
    );

    if (!kIsWeb && !hasConnection) {
      LogService.warning('No internet connection. Task rejected.', source: 'OfflineMapCubit');
      // 應發送錯誤狀態或拋出例外供 UI 處理
      throw Exception('無網路連線，無法下載地圖。');
    }

    await initStore();

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final taskName = name ?? '區域下載 ${taskId.substring(taskId.length - 4)}';

    final task = DownloadTask(id: taskId, name: taskName, bounds: bounds, minZoom: minZoom, maxZoom: maxZoom);

    if (state is OfflineMapLoaded) {
      final currentQueue = List<DownloadTask>.from((state as OfflineMapLoaded).downloadQueue);
      currentQueue.add(task);
      emit((state as OfflineMapLoaded).copyWith(downloadQueue: currentQueue));
    }

    LogService.info('Task added to queue: ${task.name}', source: 'OfflineMapCubit');
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;

    if (state is! OfflineMapLoaded) return;
    final currentState = state as OfflineMapLoaded;
    final currentQueue = currentState.downloadQueue;

    // 尋找下一個待處理任務
    final nextTaskIndex = currentQueue.indexWhere((t) => t.status == TaskStatus.pending);
    if (nextTaskIndex == -1) {
      _isQueueProcessing = false;
      return;
    }

    _isQueueProcessing = true;

    // 複製佇列以更新狀態
    var workingQueue = List<DownloadTask>.from(currentQueue);
    var task = workingQueue[nextTaskIndex];

    // 更新狀態為下載中
    task.status = TaskStatus.downloading;
    workingQueue[nextTaskIndex] = task;
    emit(currentState.copyWith(downloadQueue: workingQueue));

    try {
      LogService.info('Starting task: ${task.name}', source: 'OfflineMapCubit');

      final region = RectangleRegion(task.bounds);
      final downloadable = region.toDownloadable(
        minZoom: task.minZoom,
        maxZoom: task.maxZoom,
        options: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: currentState.packageName,
        ),
      );

      final downloadTask = _store.download.startForeground(region: downloadable);

      // 重新取得狀態/佇列，防止因外部操作導致狀態變更
      if (state is! OfflineMapLoaded) return;

      // 監聽下載進度
      task.subscription = downloadTask.downloadProgress.listen(
        (progress) {
          if (state is! OfflineMapLoaded) return;
          final loadedState = state as OfflineMapLoaded;
          final q = List<DownloadTask>.from(loadedState.downloadQueue);
          final idx = q.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            final t = q[idx];
            t.progress = progress.percentageProgress / 100.0;
            // 更新佇列並發送新狀態
            emit(loadedState.copyWith(downloadQueue: q));
          }
        },
        onError: (e) {
          LogService.error('Download error for task ${task.id}: $e', source: 'OfflineMapCubit');
          if (state is OfflineMapLoaded) {
            final loadedState = state as OfflineMapLoaded;
            final q = List<DownloadTask>.from(loadedState.downloadQueue);
            final idx = q.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              q[idx].status = TaskStatus.failed;
              emit(loadedState.copyWith(downloadQueue: q));
            }
          }
          task.subscription?.cancel();
          _isQueueProcessing = false;
          _processQueue();
        },
        onDone: () {
          LogService.info('Task completed: ${task.name}', source: 'OfflineMapCubit');
          if (state is OfflineMapLoaded) {
            final loadedState = state as OfflineMapLoaded;
            final q = List<DownloadTask>.from(loadedState.downloadQueue);
            final idx = q.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              q[idx].status = TaskStatus.completed;
              q[idx].progress = 1.0;
              emit(loadedState.copyWith(downloadQueue: q));
            }
          }
          _isQueueProcessing = false;
          _processQueue();
        },
        cancelOnError: true,
      );
    } catch (e) {
      LogService.error('Failed to start task ${task.id}: $e', source: 'OfflineMapCubit');
      if (state is OfflineMapLoaded) {
        final loadedState = state as OfflineMapLoaded;
        final q = List<DownloadTask>.from(loadedState.downloadQueue);
        final idx = q.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          q[idx].status = TaskStatus.failed;
          emit(loadedState.copyWith(downloadQueue: q));
        }
      }
      _isQueueProcessing = false;
      _processQueue();
    }
  }

  /// 取消下載任務
  ///
  /// [taskId] 任務 ID
  Future<void> cancelTask(String taskId) async {
    if (state is! OfflineMapLoaded) return;
    final loadedState = state as OfflineMapLoaded;
    final q = List<DownloadTask>.from(loadedState.downloadQueue);
    final idx = q.indexWhere((t) => t.id == taskId);

    if (idx != -1) {
      final task = q[idx];
      if (task.status == TaskStatus.downloading) {
        await task.subscription?.cancel();
      }
      task.status = TaskStatus.cancelled;
      emit(loadedState.copyWith(downloadQueue: q));

      if (task.subscription != null) {
        _isQueueProcessing = false;
        _processQueue();
      }
    }
  }

  Future<void> cancelAllDownloads() async {
    if (state is! OfflineMapLoaded) return;
    final loadedState = state as OfflineMapLoaded;
    final q = List<DownloadTask>.from(loadedState.downloadQueue);

    for (var task in q) {
      if (task.status == TaskStatus.downloading || task.status == TaskStatus.pending) {
        await task.subscription?.cancel();
        task.status = TaskStatus.cancelled;
      }
    }
    _isQueueProcessing = false;
    emit(loadedState.copyWith(downloadQueue: q));
  }

  Future<void> getStoreStats() async {
    await initStore();
    if (state is! OfflineMapLoaded) return;

    emit((state as OfflineMapLoaded).copyWith(isLoadingStats: true));

    try {
      final stats = await _store.stats.all;
      final mb = stats.size / 1024;
      emit((state as OfflineMapLoaded).copyWith(tileCount: stats.length, sizeMb: mb, isLoadingStats: false));
    } catch (e) {
      LogService.error('Error getting store stats: $e', source: 'OfflineMapCubit');
      emit((state as OfflineMapLoaded).copyWith(isLoadingStats: false));
    }
  }

  Future<void> clearStore() async {
    await initStore();
    LogService.info('Clearing all tiles in store...', source: 'OfflineMapCubit');
    try {
      await _store.manage.delete();
      await _store.manage.create();
      LogService.info('Store cleared and recreated.', source: 'OfflineMapCubit');
      // 更新統計資訊
      getStoreStats();
    } catch (e) {
      LogService.error('Error clearing store: $e', source: 'OfflineMapCubit');
    }
  }

  void reset() {
    cancelAllDownloads();
    // Keep store ready but clear queue?
    // MapProvider reset cleared queue.
    if (state is OfflineMapLoaded) {
      emit((state as OfflineMapLoaded).copyWith(downloadQueue: []));
    }
  }
}
