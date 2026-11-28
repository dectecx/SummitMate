import 'dart:convert';
import 'dart:typed_data';

/// A five point walk uphill, one point per hour, with one named and one unnamed waypoint.
Uint8List sampleGpx({bool elevation = true, bool named = true}) {
  final points = [
    for (var i = 0; i < 5; i++)
      '<trkpt lat="${23.28 + i * 0.004}" lon="121.0">${elevation ? '<ele>${2300 + i * 150}</ele>' : ''}<time>2026-05-10T0${i + 1}:00:00Z</time></trkpt>',
  ].join();
  return Uint8List.fromList(
    utf8.encode(
      '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1" creator="test">${named ? '<metadata><name>向陽山屋</name></metadata>' : ''}'
      '<wpt lat="23.28" lon="121.0"><name>登山口</name></wpt><wpt lat="23.29" lon="121.0"><name></name></wpt>'
      '<trk><trkseg>$points</trkseg></trk></gpx>',
    ),
  );
}
