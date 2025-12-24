import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  // 使用 GetIt 獲取 Package Name
  String get packageName => GetIt.instance<PackageInfo>().packageName;

  /// 初始化/確保 Store 存在
  Future<void> initStore() async {
    if (_isStoreReady) return;
    debugPrint('[MapProvider] initStore: Initializing FMTC store "osm_store"...');

    try {
      await _store.manage.create();
      debugPrint('[MapProvider] initStore: Store created/opened successfully.');
    } catch (e) {
      debugPrint('[MapProvider] initStore: Error creating store (ignoring if exists): $e');
    }
    _isStoreReady = true;
    notifyListeners();
    debugPrint('[MapProvider] initStore: State set to ready.');
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
    debugPrint('[MapProvider] downloadRegion: Starting download task (ID: $instanceId)...');

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
      debugPrint('Error loading GPX file: $e');
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
