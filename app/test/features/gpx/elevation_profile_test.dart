import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/gpx/domain/elevation_profile.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';

List<GpxPoint> _ramp(int n, {double step = 1, double lngStep = 0.001}) => [
  for (var i = 0; i < n; i++) GpxPoint(lat: 24, lng: 121 + i * lngStep, ele: 1000 + i * step),
];

void main() {
  test('haversine: one degree of latitude is about 111.19 km', () {
    expect(haversineKm(0, 0, 1, 0), closeTo(111.19, 0.05));
    expect(haversineKm(24, 121, 24, 121), 0);
  });

  group('elevationProfile', () {
    test('empty when fewer than 2 points have elevation', () {
      expect(elevationProfile(const []), isEmpty);
      expect(elevationProfile([const GpxPoint(lat: 1, lng: 1, ele: 5), const GpxPoint(lat: 1, lng: 2)]), isEmpty);
    });

    test('skips points without ele but keeps their distance', () {
      final p = elevationProfile(const [
        GpxPoint(lat: 0, lng: 0, ele: 10),
        GpxPoint(lat: 1, lng: 0),
        GpxPoint(lat: 2, lng: 0, ele: 20),
      ]);
      expect(p, hasLength(2));
      expect(p.first.distanceKm, 0);
      expect(p.last.distanceKm, closeTo(222.39, 0.1));
    });

    test('downsamples evenly keeping first and last', () {
      final pts = _ramp(1000);
      final p = elevationProfile(pts, maxPoints: 50);
      expect(p, hasLength(50));
      expect(p.first.ele, 1000);
      expect(p.last.ele, 1999);
      for (var i = 1; i < p.length; i++) {
        expect(p[i].distanceKm, greaterThan(p[i - 1].distanceKm));
      }
      expect(elevationProfile(_ramp(10), maxPoints: 50), hasLength(10));
    });
  });

  group('profileStats', () {
    test('null without elevation', () {
      expect(profileStats(const [GpxPoint(lat: 1, lng: 1)]), isNull);
    });

    test('ramp has exact ascent', () {
      final s = profileStats(_ramp(101))!;
      expect(s.ascent, closeTo(100, 1e-9));
      expect(s.descent, 0);
      expect(s.maxEle, 1100);
      expect(s.minEle, 1000);
      expect(s.distanceKm, closeTo(haversineKm(24, 121, 24, 121.1), 0.01));
    });

    test('symmetrical up then down', () {
      final pts = [..._ramp(51), for (var i = 49; i >= 0; i--) GpxPoint(lat: 24, lng: 121.1 - i * 0.001, ele: 1000.0 + i)];
      final s = profileStats(pts)!;
      // The peak is slightly flattened by smoothing.
      expect(s.ascent, closeTo(50, 3));
      expect(s.descent, closeTo(s.ascent, 1e-9));
    });

    test('noise below threshold is ignored', () {
      final rnd = math.Random(1);
      final pts = [
        for (var i = 0; i < 200; i++) GpxPoint(lat: 24, lng: 121 + i * 0.0001, ele: 1500 + (rnd.nextDouble() - 0.5) * 2),
      ];
      final s = profileStats(pts)!;
      expect(s.ascent, 0);
      expect(s.descent, 0);
    });
  });
}
