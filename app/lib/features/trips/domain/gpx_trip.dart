import 'dart:convert';

import '../../gpx/domain/elevation_profile.dart';
import '../../gpx/domain/gpx_models.dart';

/// A node proposed from a GPX file.
class ImportedNode {
  const ImportedNode({required this.dayIndex, required this.name, this.estMinutes, required this.altitude, required this.distanceKm, this.lat, this.lng});
  final int dayIndex;
  final String name;
  final int? estMinutes;
  final int altitude;

  /// Distance from the previous node along the track.
  final double distanceKm;
  final double? lat;
  final double? lng;
}

/// What a GPX file becomes: a trip with nodes and its (simplified) track.
class ImportedTrip {
  const ImportedTrip({required this.name, required this.start, required this.dayCount, required this.nodes, required this.track});
  final String name;
  final DateTime start;
  final int dayCount;
  final List<ImportedNode> nodes;
  final List<GpxPoint> track;
}

const maxStoredTrackPoints = 500;
const _taiwanOffset = Duration(hours: 8);

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

/// Turns a parsed GPX file into a trip. Waypoints become nodes in track order; without waypoints the start, the
/// highest point and the end are proposed. Days and times come from the track's timestamps (Taiwan time) when present.
ImportedTrip tripFromGpx(GpxDocument doc, {required DateTime today}) {
  final all = doc.allTrackPoints;
  final cumulative = <double>[0];
  for (var i = 1; i < all.length; i++) {
    cumulative.add(cumulative.last + haversineKm(all[i - 1].lat, all[i - 1].lng, all[i].lat, all[i].lng));
  }

  int nearest(double lat, double lng) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < all.length; i++) {
      final d = haversineKm(lat, lng, all[i].lat, all[i].lng);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  DateTime? local(GpxPoint p) => p.time?.toUtc().add(_taiwanOffset);
  final firstTime = all.isEmpty ? null : local(all.first);
  final firstDay = firstTime == null ? null : DateTime.utc(firstTime.year, firstTime.month, firstTime.day);

  ({int day, int? minutes}) when(int trackIndex) {
    final t = local(all[trackIndex]);
    if (t == null || firstDay == null) return (day: 1, minutes: null);
    final day = DateTime.utc(t.year, t.month, t.day).difference(firstDay).inDays + 1;
    return (day: day, minutes: t.hour * 60 + t.minute);
  }

  // (position along the track in km, node without distance)
  final raw = <({double km, int day, String name, int? minutes, double altitude, double? lat, double? lng})>[];
  if (doc.waypoints.isNotEmpty) {
    var fallbackKm = 0.0;
    GpxWaypoint? previous;
    for (final w in doc.waypoints) {
      if (all.isNotEmpty) {
        final i = nearest(w.lat, w.lng);
        final t = when(i);
        raw.add((km: cumulative[i], day: t.day, name: w.name, minutes: t.minutes, altitude: w.ele ?? all[i].ele ?? 0, lat: w.lat, lng: w.lng));
      } else {
        if (previous != null) fallbackKm += haversineKm(previous.lat, previous.lng, w.lat, w.lng);
        raw.add((km: fallbackKm, day: 1, name: w.name, minutes: null, altitude: w.ele ?? 0, lat: w.lat, lng: w.lng));
        previous = w;
      }
    }
    raw.sort((a, b) => a.km.compareTo(b.km));
  } else if (all.length >= 2) {
    var peak = 0;
    for (var i = 0; i < all.length; i++) {
      if ((all[i].ele ?? -1e9) > (all[peak].ele ?? -1e9)) peak = i;
    }
    for (final (index, name) in [(0, '起點'), if (peak != 0 && peak != all.length - 1) (peak, '最高點'), (all.length - 1, '終點')]) {
      final t = when(index);
      raw.add((km: cumulative[index], day: t.day, name: name, minutes: t.minutes, altitude: all[index].ele ?? 0, lat: all[index].lat, lng: all[index].lng));
    }
  }

  final nodes = <ImportedNode>[];
  for (var i = 0; i < raw.length; i++) {
    final r = raw[i];
    final gap = i == 0 ? 0.0 : r.km - raw[i - 1].km;
    nodes.add(ImportedNode(
      dayIndex: r.day < 1 ? 1 : r.day,
      name: r.name,
      estMinutes: r.minutes,
      altitude: r.altitude.round(),
      distanceKm: double.parse(gap.toStringAsFixed(2)),
      lat: r.lat,
      lng: r.lng,
    ));
  }

  final name = doc.name.isNotEmpty
      ? doc.name
      : doc.tracks.where((t) => t.name.isNotEmpty).map((t) => t.name).firstOrNull ?? '匯入的行程';
  final start = firstDay == null ? DateTime(today.year, today.month, today.day) : DateTime(firstDay.year, firstDay.month, firstDay.day);
  final dayCount = nodes.isEmpty ? 1 : nodes.map((n) => n.dayIndex).reduce((a, b) => a > b ? a : b);
  return ImportedTrip(name: name, start: start, dayCount: dayCount, nodes: nodes, track: simplifyTrack(all));
}
