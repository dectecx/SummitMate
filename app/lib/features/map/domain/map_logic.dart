import 'dart:math' as math;

import '../../explore/domain/mountain_models.dart';

/// Mountains that would be drawn (almost) on top of the one at [lat], [lng] at map zoom [zoom], within
/// [radiusPx] screen pixels. Highest first. Used so tapping one of several crowded markers lets the
/// person choose instead of silently opening whichever happens to be on top.
List<Mountain> peaksNear(List<Mountain> all, double lat, double lng, double zoom, {double radiusPx = 24}) {
  final degreesPerPixel = 360 / (256 * math.pow(2, zoom));
  final r = radiusPx * degreesPerPixel;
  final cosLat = math.cos(lat * math.pi / 180);
  return all.where((m) => (m.latitude - lat).abs() <= r && (m.longitude - lng).abs() * cosLat <= r).toList()
    ..sort((a, b) {
      final e = b.elevation.compareTo(a.elevation);
      return e != 0 ? e : a.id.compareTo(b.id);
    });
}

/// "42 MB" / "1.3 GB" style size for people.
String formatBytes(double bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
}
