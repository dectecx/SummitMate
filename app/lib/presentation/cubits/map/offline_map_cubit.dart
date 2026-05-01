import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'offline_map_state.dart';

@injectable
class OfflineMapCubit extends Cubit<OfflineMapState> {
  final FMTCStore _store = FMTCStore('osm_store');
  bool _isQueueProcessing = false;
  final Map<String, StreamSubscription> _subscriptions = {};

  OfflineMapCubit() : super(OfflineMapInitial()) {
    _init();
  }

  Future<void> _init() async {
    String packageName = '';
    try {
      packageName = GetIt.instance<PackageInfo>().packageName;
    } catch (e) {
      LogService.error('Failed to get package info: $e', source: 'OfflineMapCubit');
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
  }

  /// 下載指定區域
  Future<void> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    String? name,
  }) async {
    final hasConnection = await InternetConnectionChecker.createInstance().hasConnection;

    if (!kIsWeb && !hasConnection) {
      throw Exception('無網路連線，無法下載地圖。');
    }

    await initStore();

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final taskName = name ?? '區域下載 ${taskId.substring(taskId.length - 4)}';

    final task = DownloadTask(
      id: taskId,
      name: taskName,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      status: TaskStatus.pending,
    );

    if (state is OfflineMapLoaded) {
      final currentState = state as OfflineMapLoaded;
      final currentQueue = List<DownloadTask>.from(currentState.downloadQueue);
      currentQueue.add(task);
      emit(currentState.copyWith(downloadQueue: currentQueue));
    }

    LogService.info('Task added to queue: ${task.name}', source: 'OfflineMapCubit');
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;

    if (state is! OfflineMapLoaded) return;
    final currentState = state as OfflineMapLoaded;
    final currentQueue = currentState.downloadQueue;

    final nextTaskIndex = currentQueue.indexWhere((t) => t.status == TaskStatus.pending);
    if (nextTaskIndex == -1) {
      _isQueueProcessing = false;
      return;
    }

    _isQueueProcessing = true;

    var workingQueue = List<DownloadTask>.from(currentQueue);
    var task = workingQueue[nextTaskIndex].copyWith(status: TaskStatus.downloading);
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

      if (state is! OfflineMapLoaded) return;

      _subscriptions[task.id] = downloadTask.downloadProgress.listen(
        (progress) {
          if (state is! OfflineMapLoaded) return;
          final loadedState = state as OfflineMapLoaded;
          final q = List<DownloadTask>.from(loadedState.downloadQueue);
          final idx = q.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            q[idx] = q[idx].copyWith(progress: progress.percentageProgress / 100.0);
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
              q[idx] = q[idx].copyWith(status: TaskStatus.failed);
              emit(loadedState.copyWith(downloadQueue: q));
            }
          }
          _subscriptions[task.id]?.cancel();
          _subscriptions.remove(task.id);
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
              q[idx] = q[idx].copyWith(status: TaskStatus.completed, progress: 1.0);
              emit(loadedState.copyWith(downloadQueue: q));
            }
          }
          _subscriptions.remove(task.id);
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
          q[idx] = q[idx].copyWith(status: TaskStatus.failed);
          emit(loadedState.copyWith(downloadQueue: q));
        }
      }
      _isQueueProcessing = false;
      _processQueue();
    }
  }

  Future<void> cancelTask(String taskId) async {
    if (state is! OfflineMapLoaded) return;
    final loadedState = state as OfflineMapLoaded;
    final q = List<DownloadTask>.from(loadedState.downloadQueue);
    final idx = q.indexWhere((t) => t.id == taskId);

    if (idx != -1) {
      final task = q[idx];
      if (task.status == TaskStatus.downloading) {
        await _subscriptions[taskId]?.cancel();
        _subscriptions.remove(taskId);
      }
      q[idx] = task.copyWith(status: TaskStatus.cancelled);
      emit(loadedState.copyWith(downloadQueue: q));

      if (task.status == TaskStatus.downloading) {
        _isQueueProcessing = false;
        _processQueue();
      }
    }
  }

  Future<void> cancelAllDownloads() async {
    if (state is! OfflineMapLoaded) return;
    final loadedState = state as OfflineMapLoaded;
    final q = List<DownloadTask>.from(loadedState.downloadQueue);

    for (var i = 0; i < q.length; i++) {
      final task = q[i];
      if (task.status == TaskStatus.downloading || task.status == TaskStatus.pending) {
        await _subscriptions[task.id]?.cancel();
        _subscriptions.remove(task.id);
        q[i] = task.copyWith(status: TaskStatus.cancelled);
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
      getStoreStats();
    } catch (e) {
      LogService.error('Error clearing store: $e', source: 'OfflineMapCubit');
    }
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }

  void reset() {
    cancelAllDownloads();
    if (state is OfflineMapLoaded) {
      emit((state as OfflineMapLoaded).copyWith(downloadQueue: []));
    }
  }
}
