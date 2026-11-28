import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/gpx/domain/gpx_codec.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';

const _gpx11 = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="x" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3">
  <metadata><name>雪山主東線</name></metadata>
  <wpt lat="24.3835" lon="121.2330"><ele>3886.5</ele><name>主峰</name><desc>山頂</desc></wpt>
  <wpt lat="24.4" lon="121.2"><name>七卡</name><cmt>備註</cmt></wpt>
  <wpt lat="95" lon="121"><name>bad</name></wpt>
  <trk>
    <name>Day 1</name>
    <extensions><gpxx:TrackExtension/></extensions>
    <trkseg>
      <trkpt lat="24.1" lon="121.1"><ele>2000</ele><time>2024-05-01T01:00:00Z</time></trkpt>
      <trkpt lat="24.2" lon="121.2"><time>2024-05-01T02:00:00+08:00</time></trkpt>
      <trkpt lat="abc" lon="121.3"><ele>1</ele></trkpt>
      <trkpt lat="24.3"><ele>1</ele></trkpt>
      <trkpt lat="24.3" lon="181"><ele>1</ele></trkpt>
    </trkseg>
    <trkseg>
      <trkpt lat="24.4" lon="121.4"><ele>2500</ele></trkpt>
    </trkseg>
  </trk>
</gpx>''';

const _gpx10 = '''<?xml version="1.0"?>
<gpx version="1.0" creator="old" xmlns="http://www.topografix.com/GPX/1/0">
  <name>Old file</name>
  <rte><name>Route A</name>
    <rtept lat="23.5" lon="120.9"><ele>100</ele></rtept>
    <rtept lat="23.6" lon="121.0"><ele>200</ele></rtept>
  </rte>
</gpx>''';

void main() {
  group('parseGpx', () {
    test('parses GPX 1.1 with extensions and bad points', () {
      final doc = parseGpx(_gpx11);
      expect(doc.name, '雪山主東線');
      expect(doc.waypoints.map((w) => w.name), ['主峰', '七卡']);
      expect(doc.waypoints[0].ele, 3886.5);
      expect(doc.waypoints[0].description, '山頂');
      expect(doc.waypoints[1].ele, isNull);
      expect(doc.waypoints[1].description, '備註');
      expect(doc.tracks, hasLength(1));
      final pts = doc.tracks.single.points;
      expect(pts, hasLength(3));
      expect(doc.tracks.single.name, 'Day 1');
      expect(pts[0].time, DateTime.utc(2024, 5, 1, 1));
      expect(pts[1].ele, isNull);
      expect(pts[1].time, DateTime.utc(2024, 4, 30, 18));
      expect(pts[2].ele, 2500);
      expect(doc.allTrackPoints, hasLength(3));
    });

    test('parses GPX 1.0 top-level name and routes', () {
      final doc = parseGpx(_gpx10);
      expect(doc.name, 'Old file');
      expect(doc.waypoints, isEmpty);
      expect(doc.tracks.single.name, 'Route A');
      expect(doc.tracks.single.points.map((p) => p.ele), [100, 200]);
    });

    test('parses without namespace', () {
      final doc = parseGpx('<gpx><wpt lat="1" lon="2"/></gpx>');
      expect(doc.waypoints.single.name, '');
      expect(doc.waypoints.single.lng, 2);
    });

    test('throws on non-XML', () {
      expect(() => parseGpx('not xml <<'), throwsA(isA<GpxFormatException>()));
    });

    test('throws on wrong root', () {
      expect(() => parseGpx('<kml><wpt lat="1" lon="2"/></kml>'), throwsA(isA<GpxFormatException>()));
    });

    test('throws when there is nothing usable', () {
      expect(() => parseGpx('<gpx><trk><trkseg/></trk></gpx>'), throwsA(isA<GpxFormatException>()));
      expect(() => parseGpx('<gpx><wpt lat="x" lon="2"/></gpx>'), throwsA(isA<GpxFormatException>()));
    });
  });

}
