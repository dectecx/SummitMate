import 'dart:math' as math;

import 'package:summitmate/features/gpx/domain/gpx_models.dart';

class ProfilePoint {
  const ProfilePoint(this.distanceKm, this.ele);

  final double distanceKm;
  final double ele;
}

class ProfileStats {
  const ProfileStats({
    required this.distanceKm,
    required this.ascent,
    required this.descent,
    required this.maxEle,
    required this.minEle,
  });

  final double distanceKm;
  final double ascent;
  final double descent;
  final double maxEle;
  final double minEle;
}

/// Great-circle distance in km.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0088;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// Distance/elevation samples, downsampled evenly to at most [maxPoints] (first and last kept).
List<ProfilePoint> elevationProfile(List<GpxPoint> points, {int maxPoints = 400}) {
  final all = <ProfilePoint>[];
  var dist = 0.0;
  for (var i = 0; i < points.length; i++) {
    if (i > 0) dist += haversineKm(points[i - 1].lat, points[i - 1].lng, points[i].lat, points[i].lng);
    final ele = points[i].ele;
    if (ele != null) all.add(ProfilePoint(dist, ele));
  }
  if (all.length < 2) return const [];
  if (maxPoints < 2 || all.length <= maxPoints) return all;
  final last = all.length - 1;
  return [for (var i = 0; i < maxPoints; i++) all[(i * last / (maxPoints - 1)).round()]];
}

/// Null when there is no usable elevation. Ascent/descent use smoothed elevation with a 2 m hysteresis.
ProfileStats? profileStats(List<GpxPoint> points) {
  var distance = 0.0;
  for (var i = 1; i < points.length; i++) {
    distance += haversineKm(points[i - 1].lat, points[i - 1].lng, points[i].lat, points[i].lng);
  }
  final eles = [
    for (final p in points)
      if (p.ele != null) p.ele!,
  ];
  if (eles.isEmpty) return null;

  final smooth = _smooth(eles, 2);
  const threshold = 2.0;
  var ascent = 0.0;
  var descent = 0.0;
  var ref = smooth.first;
  for (final v in smooth.skip(1)) {
    final d = v - ref;
    if (d >= threshold) {
      ascent += d;
      ref = v;
    } else if (d <= -threshold) {
      descent -= d;
      ref = v;
    }
  }
  return ProfileStats(
    distanceKm: distance,
    ascent: ascent,
    descent: descent,
    maxEle: eles.reduce(math.max),
    minEle: eles.reduce(math.min),
  );
}

/// Moving average with a symmetric window that shrinks at the ends, so endpoints stay unchanged.
List<double> _smooth(List<double> v, int half) {
  final out = List<double>.filled(v.length, 0);
  for (var i = 0; i < v.length; i++) {
    final h = math.min(half, math.min(i, v.length - 1 - i));
    var sum = 0.0;
    for (var j = i - h; j <= i + h; j++) {
      sum += v[j];
    }
    out[i] = sum / (2 * h + 1);
  }
  return out;
}
