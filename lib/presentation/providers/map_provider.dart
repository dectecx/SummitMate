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

  Position? get currentLocation => _currentLocation;
  double? get currentHeading => _currentHeading;

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
  Future<void> downloadRegion({
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
    // 每次下載使用獨立 ID (或固定 ID 1, 但需確保沒有並發)
    // 這裡使用時間戳記作為 ID
    final instanceId = DateTime.now().millisecondsSinceEpoch;
    LogService.info('downloadRegion: Starting download task (ID: $instanceId)...', source: 'MapProvider');

    final downloadTask = _store.download.startForeground(
      region: downloadable,
      instanceId: instanceId, // 修正 "ID 0 already exists"
      parallelThreads: 5,
      maxBufferLength: 200,
      skipExistingTiles: true,
      skipSeaTiles: true,
    );

    // 監聽進度
    await for (final event in downloadTask.downloadProgress) {
      if (onProgress != null) {
        // 嘗試使用 percentageProgress
        final percent = event.percentageProgress / 100.0;
        onProgress(percent);
      }
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
