import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

class MapProvider with ChangeNotifier {
  Gpx? _gpx;
  List<LatLng> _trackPoints = [];
  bool _isLoading = false;

  Gpx? get gpx => _gpx;
  List<LatLng> get trackPoints => _trackPoints;
  bool get isLoading => _isLoading;

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
