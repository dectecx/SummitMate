import 'elevation_profile.dart';
import 'gpx_models.dart';

/// A route ready to be shown: its points with the distance walked up to each of them.
class TrackRoute {
  TrackRoute({required this.name, required this.points, this.waypoints = const []}) : distancesKm = _distances(points);

  final String name;
  final List<GpxPoint> points;

  /// Named points of the file, shown as pins. They never become itinerary nodes.
  final List<GpxWaypoint> waypoints;

  /// Same length as [points].
  final List<double> distancesKm;

  double get lengthKm => distancesKm.isEmpty ? 0 : distancesKm.last;

  /// The index of the point closest to [km] along the route.
  int indexAt(double km) {
    var low = 0, high = points.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (distancesKm[mid] < km) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low > 0 && km - distancesKm[low - 1] < distancesKm[low] - km ? low - 1 : low;
  }

  /// Time from the first recorded point to point [index]; null when the file has no times there.
  Duration? elapsedAt(int index) {
    final start = points.first.time, at = points[index].time;
    if (start == null || at == null || at.isBefore(start)) return null;
    return at.difference(start);
  }

  static List<double> _distances(List<GpxPoint> p) {
    var sum = 0.0;
    return [
      for (var i = 0; i < p.length; i++) i == 0 ? 0.0 : sum += haversineKm(p[i - 1].lat, p[i - 1].lng, p[i].lat, p[i].lng),
    ];
  }
}

/// The route of a parsed file: all its tracks joined. Throws [GpxFormatException] when there is no line to draw.
TrackRoute routeOf(GpxDocument doc, {required String fallbackName}) {
  final points = doc.allTrackPoints;
  if (points.length < 2) throw const GpxFormatException('檔案裡沒有軌跡');
  final name = [doc.name, for (final t in doc.tracks) t.name, fallbackName].map((n) => n.trim()).firstWhere((n) => n.isNotEmpty, orElse: () => '路線');
  return TrackRoute(name: name, points: points, waypoints: [for (final w in doc.waypoints) if (w.name.trim().isNotEmpty) w]);
}
