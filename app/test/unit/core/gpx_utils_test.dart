import 'package:flutter_test/flutter_test.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:summitmate/core/gpx_utils.dart';

void main() {
  group('GpxUtils', () {
    group('extractTrackPoints', () {
      test('extracts points from single track with single segment', () {
        final gpx = Gpx();
        final trk = Trk();
        final seg = Trkseg();
        seg.trkpts = [Wpt(lat: 23.5, lon: 121.0), Wpt(lat: 23.6, lon: 121.1), Wpt(lat: 23.7, lon: 121.2)];
        trk.trksegs = [seg];
        gpx.trks = [trk];

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points.length, 3);
        expect(points[0].latitude, 23.5);
        expect(points[0].longitude, 121.0);
        expect(points[2].latitude, 23.7);
      });

      test('extracts points from multiple tracks', () {
        final gpx = Gpx();

        final trk1 = Trk();
        final seg1 = Trkseg();
        seg1.trkpts = [Wpt(lat: 23.5, lon: 121.0)];
        trk1.trksegs = [seg1];

        final trk2 = Trk();
        final seg2 = Trkseg();
        seg2.trkpts = [Wpt(lat: 24.0, lon: 121.5)];
        trk2.trksegs = [seg2];

        gpx.trks = [trk1, trk2];

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points.length, 2);
      });

      test('extracts points from multiple segments in one track', () {
        final gpx = Gpx();
        final trk = Trk();

        final seg1 = Trkseg();
        seg1.trkpts = [Wpt(lat: 23.5, lon: 121.0)];

        final seg2 = Trkseg();
        seg2.trkpts = [Wpt(lat: 23.6, lon: 121.1)];

        trk.trksegs = [seg1, seg2];
        gpx.trks = [trk];

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points.length, 2);
      });

      test('returns empty list for empty GPX', () {
        final gpx = Gpx();

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points, isEmpty);
      });

      test('filters out points with null lat', () {
        final gpx = Gpx();
        final trk = Trk();
        final seg = Trkseg();
        seg.trkpts = [
          Wpt(lat: 23.5, lon: 121.0),
          Wpt(lat: null, lon: 121.1), // null lat
          Wpt(lat: 23.7, lon: 121.2),
        ];
        trk.trksegs = [seg];
        gpx.trks = [trk];

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points.length, 2);
      });

      test('filters out points with null lon', () {
        final gpx = Gpx();
        final trk = Trk();
        final seg = Trkseg();
        seg.trkpts = [
          Wpt(lat: 23.5, lon: 121.0),
          Wpt(lat: 23.6, lon: null), // null lon
          Wpt(lat: 23.7, lon: 121.2),
        ];
        trk.trksegs = [seg];
        gpx.trks = [trk];

        final points = GpxUtils.extractTrackPoints(gpx);

        expect(points.length, 2);
      });
    });

    group('calculateTotalDistance', () {
      test('returns 0 for empty list', () {
        final distance = GpxUtils.calculateTotalDistance([]);
        expect(distance, 0.0);
      });

      test('returns 0 for single point', () {
        final distance = GpxUtils.calculateTotalDistance([LatLng(23.5, 121.0)]);
        expect(distance, 0.0);
      });

      test('calculates distance between two points', () {
        // 約 11km 的距離 (緯度差 0.1 度)
        final points = [LatLng(23.5, 121.0), LatLng(23.6, 121.0)];

        final distance = GpxUtils.calculateTotalDistance(points);

        expect(distance, greaterThan(10));
        expect(distance, lessThan(12));
      });

      test('calculates cumulative distance for multiple points', () {
        final points = [LatLng(23.5, 121.0), LatLng(23.6, 121.0), LatLng(23.7, 121.0)];

        final distance = GpxUtils.calculateTotalDistance(points);

        // 應該約為 22km (2 段 * 11km)
        expect(distance, greaterThan(20));
        expect(distance, lessThan(24));
      });
    });

    group('calculateCenter', () {
      test('returns null for empty list', () {
        final center = GpxUtils.calculateCenter([]);
        expect(center, isNull);
      });

      test('returns the point for single point', () {
        final center = GpxUtils.calculateCenter([LatLng(23.5, 121.0)]);
        expect(center?.latitude, 23.5);
        expect(center?.longitude, 121.0);
      });

      test('calculates center of two points', () {
        final points = [LatLng(23.0, 121.0), LatLng(24.0, 122.0)];

        final center = GpxUtils.calculateCenter(points);

        expect(center?.latitude, 23.5);
        expect(center?.longitude, 121.5);
      });

      test('calculates center of multiple points', () {
        final points = [LatLng(23.0, 121.0), LatLng(24.0, 121.0), LatLng(23.0, 122.0), LatLng(24.0, 122.0)];

        final center = GpxUtils.calculateCenter(points);

        expect(center?.latitude, 23.5);
        expect(center?.longitude, 121.5);
      });
    });
  });
}
