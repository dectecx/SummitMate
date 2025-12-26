import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

/// GPX 解析工具
/// 提供純邏輯的 GPX 處理功能，便於單元測試
class GpxUtils {
  /// 從 GPX 物件提取所有軌跡點
  /// 過濾掉 lat 或 lon 為 null 的點
  static List<LatLng> extractTrackPoints(Gpx gpx) {
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

  /// 計算軌跡總距離 (公里)
  static double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    const distance = Distance();
    double total = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, points[i], points[i + 1]);
    }

    return total;
  }

  /// 計算軌跡中心點
  static LatLng? calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return null;

    double sumLat = 0.0;
    double sumLng = 0.0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }
}
