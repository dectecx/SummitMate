/// A single track or route point.
class GpxPoint {
  const GpxPoint({required this.lat, required this.lng, this.ele, this.time});

  final double lat;
  final double lng;

  /// Elevation in metres, null when the file has none.
  final double? ele;
  final DateTime? time;
}

class GpxWaypoint {
  const GpxWaypoint({required this.name, required this.lat, required this.lng, this.ele, this.description = ''});

  final String name;
  final double lat;
  final double lng;
  final double? ele;
  final String description;
}

class GpxTrack {
  const GpxTrack({required this.name, required this.points});

  final String name;
  final List<GpxPoint> points;
}

class GpxDocument {
  const GpxDocument({this.name = '', this.waypoints = const [], this.tracks = const []});

  final String name;
  final List<GpxWaypoint> waypoints;
  final List<GpxTrack> tracks;

  /// All tracks concatenated in order.
  List<GpxPoint> get allTrackPoints => [for (final t in tracks) ...t.points];
}

class GpxFormatException implements Exception {
  const GpxFormatException(this.message);

  final String message;

  @override
  String toString() => 'GpxFormatException: $message';
}
