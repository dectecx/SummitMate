import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../services/log_service.dart';

enum TaskStatus { pending, downloading, paused, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String name;
  final LatLngBounds bounds;
  final int minZoom;
  final int maxZoom;
  TaskStatus status;
  double progress;
  int successfulTiles;
  int failedTiles;
  StreamSubscription<DownloadProgress>? subscription;

  DownloadTask({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
    this.successfulTiles = 0,
    this.failedTiles = 0,
  });
}

class MapProvider with ChangeNotifier {
  Gpx? _gpx;
  List<LatLng> _trackPoints = [];
  bool _isLoading = false;
  bool _isStoreReady = false;

  // FMTC Store
  final FMTCStore _store = FMTCStore('osm_store');
  FMTCStore get store => _store;

  Gpx? get gpx => _gpx;
  List<LatLng> get trackPoints => _trackPoints;
  bool get isLoading => _isLoading;
  bool get isStoreReady => _isStoreReady;

  // Location & Compass
  Position? _currentLocation;
  double? _currentHeading;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;

  // Download Queue
  final List<DownloadTask> _downloadQueue = [];
  bool _isQueueProcessing = false;

  Position? get currentLocation => _currentLocation;
  double? get currentHeading => _currentHeading;

  List<DownloadTask> get downloadQueue => List.unmodifiable(_downloadQueue);
  bool get isDownloading => _downloadQueue.any((t) => t.status == TaskStatus.downloading);
  // 相容舊 getter, 回傳第一個正在下載或排隊的進度
  double get downloadProgress => _downloadQueue.isNotEmpty ? _downloadQueue.first.progress : 0.0;

  // 使用 GetIt 獲取 Package Name
  String get packageName => GetIt.instance<PackageInfo>().packageName;

  /// 初始化/確保 Store 存在
  Future<void> initStore() async {
    if (_isStoreReady) return;
    LogService.info('Initializing FMTC store "osm_store"...', source: 'MapProvider');

    try {
      await _store.manage.create();
      LogService.info('Store created/opened successfully.', source: 'MapProvider');
    } catch (e) {
      LogService.warning('Error creating store (ignoring if exists): $e', source: 'MapProvider');
    }
    _isStoreReady = true;
    notifyListeners();
    LogService.info('State set to ready.', source: 'MapProvider');

    // 初始化定位 (非阻塞)
    initLocation();
  }

  /// 初始化定位與羅盤
  Future<void> initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 檢查定位服務是否開啟
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      LogService.warning('Location services are disabled.', source: 'MapProvider');
      return;
    }

    // 2. 檢查權限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        LogService.warning('Location permissions are denied', source: 'MapProvider');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      LogService.warning('Location permissions are permanently denied.', source: 'MapProvider');
      return;
    }

    // 3. 開始監聽定位
    _startLocationUpdates();

    // 4. 開始監聽羅盤 (Web 不支援 flutter_compass)
    if (!kIsWeb) {
      _startCompassUpdates();
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 每 5 公尺更新一次
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      _currentLocation = position;
      notifyListeners();
    }, onError: (e) => LogService.error('Location Stream Error: $e', source: 'MapProvider'));
  }

  void _startCompassUpdates() {
    _compassStreamSubscription?.cancel();
    _compassStreamSubscription = FlutterCompass.events?.listen((event) {
      _currentHeading = event.heading;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    super.dispose();
  }

  /// 下載指定區域
  /// 回傳是否成功 (Future completes when download finishes or cancels)
  /// 加入下載任務至佇列
  Future<void> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    String? name,
    Function(double progress)? onProgress,
  }) async {
    // 檢查網路
    final hasConnection = await InternetConnectionChecker.createInstance().hasConnection;
    LogService.info('Download requested. Connectivity: ${hasConnection ? "Online" : "Offline"}', source: 'MapProvider');
    
    if (!kIsWeb && !hasConnection) {
      LogService.warning('No internet connection. Task rejected.', source: 'MapProvider');
      throw Exception('無網路連線，無法下載地圖。');
    }

    await initStore();

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final taskName = name ?? '區域下載 ${taskId.substring(taskId.length - 4)}';

    final task = DownloadTask(id: taskId, name: taskName, bounds: bounds, minZoom: minZoom, maxZoom: maxZoom);

    _downloadQueue.add(task);
    notifyListeners();
    LogService.info('Task added to queue: ${task.name}', source: 'MapProvider');

    _processQueue();
  }

  /// 處理佇列
  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;

    // 找出下一個 Pending 的任務
    final nextTaskIndex = _downloadQueue.indexWhere((t) => t.status == TaskStatus.pending);
    if (nextTaskIndex == -1) {
      _isQueueProcessing = false;
      return;
    }

    _isQueueProcessing = true;
    final task = _downloadQueue[nextTaskIndex];
    task.status = TaskStatus.downloading;
    notifyListeners();

    try {
      LogService.info('Starting task: ${task.name}', source: 'MapProvider');

      final region = RectangleRegion(task.bounds);
      final downloadable = region.toDownloadable(
        minZoom: task.minZoom,
        maxZoom: task.maxZoom,
        options: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: packageName,
        ),
      );

      final downloadTask = await _store.download.startForeground(
        region: downloadable,
        // FMTC v10: retry handling is automatic or configured elsewhere store.manage.config
      );

      task.subscription = downloadTask.downloadProgress.listen(
        (progress) {
          task.progress = progress.percentageProgress / 100.0;
          
          // Log progress every ~10%
          if ((task.progress * 100).round() % 10 == 0 && task.progress > 0) {
             LogService.debug('Task ${task.name} progress: ${(task.progress * 100).toStringAsFixed(0)}%', source: 'MapProvider');
          }

          // task.successfulTiles = progress.successfulTiles; // Undefined in v10?
          // task.failedTiles = progress.failedTiles;         // Undefined in v10?
          notifyListeners();
        },
        onError: (e) {
          LogService.error('Download error for task ${task.id}: $e', source: 'MapProvider');
          task.status = TaskStatus.failed;
          notifyListeners();
          task.subscription?.cancel();
          _isQueueProcessing = false;
          _processQueue(); // 繼續下一個
        },
        onDone: () {
          LogService.info('Task completed: ${task.name}', source: 'MapProvider');
          // 檢查是否有失敗過多
          if (task.failedTiles > 0 && task.successfulTiles == 0) {
            task.status = TaskStatus.failed;
          } else {
            task.status = TaskStatus.completed;
            task.progress = 1.0;
          }
          notifyListeners();
          _isQueueProcessing = false;
          _processQueue(); // 繼續下一個
        },
        cancelOnError: true, // 遇到錯就取消，由 onError 處理
      );
    } catch (e) {
      LogService.error('Failed to start task ${task.id}: $e', source: 'MapProvider');
      task.status = TaskStatus.failed;
      _isQueueProcessing = false;
      notifyListeners();
      _processQueue();
    }
  }

  /// 取消任務
  Future<void> cancelTask(String taskId) async {
    final index = _downloadQueue.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _downloadQueue[index];
      if (task.status == TaskStatus.downloading) {
        await task.subscription?.cancel();
      }
      task.status = TaskStatus.cancelled;
      notifyListeners();

      // 如果是用正在執行的，要釋放旗標並繼續
      if (task.subscription != null) {
        _isQueueProcessing = false;
        _processQueue();
      }
    }
  }

  /// 取消目前所有任務
  Future<void> cancelAllDownloads() async {
    for (var task in _downloadQueue) {
      if (task.status == TaskStatus.downloading || task.status == TaskStatus.pending) {
        await task.subscription?.cancel();
        task.status = TaskStatus.cancelled;
      }
    }
    _isQueueProcessing = false;
    notifyListeners();
  }

  // 為了相容就 API (MapScreen使用)
  Future<void> cancelDownload() async {
    await cancelAllDownloads();
  }

  /// 取得 Store 統計資訊 (Tile 數量, 大小 MB)
  Future<({int tileCount, double sizeMb})> getStoreStats() async {
    await initStore();
    try {
      final stats = await _store.stats.all;
      // Note: stats.size is in KB
      final mb = stats.size / 1024;
      return (tileCount: stats.length, sizeMb: mb);
    } catch (e) {
      LogService.error('Error getting store stats: $e', source: 'MapProvider');
      return (tileCount: 0, sizeMb: 0.0);
    }
  }

  /// 清除所有離線圖資
  Future<void> clearStore() async {
    await initStore();
    LogService.info('Clearing all tiles in store...', source: 'MapProvider');
    try {
      // 重置管理區塊 (這會清除該 Store 下的所有 Tiles)
      // await _store.manage.reset(); // FMTC v9+ supports reset
      // 替代方案: 刪除整個 Store 目錄 (如果 FMTC API 行為不同)
      // 但標準做法是使用 manage.reset() 或 manage.delete() 再重建

      // 注意: reset 可能是耗時操作
      await _store.manage.delete();
      await _store.manage.create(); // 重建

      LogService.info('Store cleared and recreated.', source: 'MapProvider');
      notifyListeners();
    } catch (e) {
      LogService.error('Error clearing store: $e', source: 'MapProvider');
    }
  }

  /// 讀取並解析 GPX 檔案
  Future<void> loadGpxFile() async {
    try {
      _setLoading(true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['gpx']);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final xmlString = await file.readAsString();

        // 解析 GPX
        _gpx = GpxReader().fromString(xmlString);

        // 提取軌跡點
        _trackPoints = _extractTrackPoints(_gpx!);

        notifyListeners();
      }
    } catch (e) {
      LogService.error('Error loading GPX file: $e', source: 'MapProvider');
      // 可以在這裡加入錯誤處理機制，例如顯示 SnackBar (需 Context 或 Service)
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearGpx() {
    _gpx = null;
    _trackPoints = [];
    notifyListeners();
  }

  List<LatLng> _extractTrackPoints(Gpx gpx) {
    List<LatLng> points = [];

    // 遍歷所有的 Tracks
    for (var trk in gpx.trks) {
      // 遍歷 Track 中的所有 Segments
      for (var seg in trk.trksegs) {
        // 遍歷 Segment 中的所有 Points
        for (var pt in seg.trkpts) {
          if (pt.lat != null && pt.lon != null) {
            points.add(LatLng(pt.lat!, pt.lon!));
          }
        }
      }
    }
    return points;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
