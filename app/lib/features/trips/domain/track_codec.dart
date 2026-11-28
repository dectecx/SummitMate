import 'dart:convert';

import '../../gpx/domain/gpx_models.dart';

/// The route stored on a trip, which teammates receive through sync: a simplified copy of a GPX track.
const maxStoredTrackPoints = 500;

/// Keeps at most [maxPoints] points, evenly by index, always including the first and the last.
List<GpxPoint> simplifyTrack(List<GpxPoint> points, {int maxPoints = maxStoredTrackPoints}) {
  if (points.length <= maxPoints || maxPoints < 2) return points;
  final out = <GpxPoint>[];
  for (var i = 0; i < maxPoints; i++) {
    out.add(points[(i * (points.length - 1) / (maxPoints - 1)).round()]);
  }
  return out;
}

/// Compact JSON `[[lat,lng,ele],...]` (ele is null without elevation). 5 decimals is about 1 m.
String encodeTrack(List<GpxPoint> points) => jsonEncode([
  for (final p in points) [double.parse(p.lat.toStringAsFixed(5)), double.parse(p.lng.toStringAsFixed(5)), p.ele?.round()],
]);

List<GpxPoint> decodeTrack(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    return [
      for (final e in jsonDecode(json) as List)
        GpxPoint(lat: (e[0] as num).toDouble(), lng: (e[1] as num).toDouble(), ele: e[2] == null ? null : (e[2] as num).toDouble()),
    ];
  } on Object {
    return const []; // a damaged track must never break the trip screen
  }
}
