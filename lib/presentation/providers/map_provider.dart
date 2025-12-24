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
import '../../services/log_service.dart';

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

  // Download Task
  StreamSubscription<DownloadProgress>? _downloadSubscription;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Position? get currentLocation => _currentLocation;
  double? get currentHeading => _currentHeading;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

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
  Future<bool> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    Function(double progress)? onProgress,
  }) async {
    await initStore();

    final region = RectangleRegion(bounds);
    final downloadable = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: packageName,
      ),
    );

    // 開始下載
    final instanceId = DateTime.now().millisecondsSinceEpoch;
    LogService.info('downloadRegion: Starting download task (ID: $instanceId)...', source: 'MapProvider');

    final downloadTask = _store.download.startForeground(
      region: downloadable,
      instanceId: instanceId,
      parallelThreads: 5,
      maxBufferLength: 200,
      skipExistingTiles: true,
      skipSeaTiles: true,
    );

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    final completer = Completer<bool>(); // 用於等待下載完成

    _downloadSubscription?.cancel();
    _downloadSubscription = downloadTask.downloadProgress.listen(
      (event) {
        if (onProgress != null) {
          final percent = event.percentageProgress / 100.0;
          onProgress(percent);
        }

        // Update local progress state
        _downloadProgress = event.percentageProgress / 100.0;
        notifyListeners();
      }, // FMTC v8/v9 stats: check if percentageProgress == 100 or rely on onDone
      onError: (e) {
        LogService.error('Download task failed: $e', source: 'MapProvider');
        completer.complete(false);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(true); // 視為完成 (或被取消)
        }
        _isDownloading = false;
        _downloadProgress = 0.0;
        notifyListeners();
      },
      cancelOnError: true,
    );

    try {
      return await completer.future;
    } catch (e) {
      LogService.error('Download await failed: $e', source: 'MapProvider');
      return false;
    } finally {
      // 確保狀態重置 (雖然 onDone 也會處理，但在異常時多一層保險)
      if (_isDownloading) {
        _isDownloading = false;
        notifyListeners();
      }
    }
  }

  /// 取消目前的下載任務
  Future<void> cancelDownload() async {
    if (_downloadSubscription != null) {
      LogService.info('Cancelling download task...', source: 'MapProvider');
      await _downloadSubscription!.cancel();
      _downloadSubscription = null;
      _isDownloading = false;
      notifyListeners();
      LogService.info('Download task cancelled.', source: 'MapProvider');
    }
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
