import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../domain/elevation_profile.dart';
import '../domain/gpx_codec.dart';
import '../domain/gpx_models.dart';
import '../domain/track_route.dart';

/// Larger files are parsed away from the screen's thread.
const _parseInBackgroundAbove = 400 * 1024;

/// The largest file accepted: far beyond a multi-day track, small enough to read into memory.
const maxGpxBytes = 30 * 1024 * 1024;

class GpxTooLargeException implements Exception {
  const GpxTooLargeException();
}

/// The routes kept on this phone: a copy of each imported file, and a row describing it.
class GpxLibrary {
  GpxLibrary(this._db, this._directory, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Future<Directory> Function() _directory;
  final DateTime Function() _now;

  Stream<List<GpxRoute>> watch() => (_db.select(_db.gpxRoutes)..orderBy([(r) => OrderingTerm.desc(r.importedAt)])).watch();

  Future<File> fileOf(String id) async => File('${(await _directory()).path}/$id.gpx');

  /// Copies a GPX file into the app. Importing the same content again returns the route already there
  /// (`isNew` false). Throws [GpxFormatException] or [GpxTooLargeException].
  Future<({GpxRoute route, bool isNew})> add(Uint8List bytes, {required String fileName}) async {
    if (bytes.length > maxGpxBytes) throw const GpxTooLargeException();
    final data = await _parse(bytes, fileName.replaceFirst(RegExp(r'\.gpx$', caseSensitive: false), ''));
    for (final r in await (_db.select(_db.gpxRoutes)..where((r) => r.sizeBytes.equals(bytes.length))).get()) {
      final file = await fileOf(r.id);
      if (file.existsSync() && _same(await file.readAsBytes(), bytes)) return (route: r, isNew: false);
    }
    final id = const Uuid().v4();
    final file = await fileOf(id);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    final stats = profileStats(data.points);
    final row = GpxRoute(
      id: id,
      name: data.name,
      distanceKm: data.lengthKm,
      ascent: stats?.ascent,
      descent: stats?.descent,
      hasTime: data.points.any((p) => p.time != null),
      sizeBytes: bytes.length,
      importedAt: _now(),
    );
    await _db.into(_db.gpxRoutes).insert(row);
    return (route: row, isNew: true);
  }

  /// The full route of a saved file, or null when it is gone.
  Future<TrackRoute?> load(String id) async {
    final row = await (_db.select(_db.gpxRoutes)..where((r) => r.id.equals(id))).getSingleOrNull();
    final file = await fileOf(id);
    if (row == null || !file.existsSync()) return null;
    final data = await _parse(await file.readAsBytes(), row.name);
    return TrackRoute(name: row.name, points: data.points, waypoints: data.waypoints);
  }

  Future<void> rename(String id, String name) => (_db.update(_db.gpxRoutes)..where((r) => r.id.equals(id))).write(GpxRoutesCompanion(name: Value(name)));

  Future<void> delete(String id) async {
    final file = await fileOf(id);
    if (file.existsSync()) await file.delete();
    await (_db.delete(_db.gpxRoutes)..where((r) => r.id.equals(id))).go();
  }

  static Future<TrackRoute> _parse(Uint8List bytes, String fallbackName) {
    TrackRoute work() => routeOf(parseGpx(utf8.decode(bytes, allowMalformed: true)), fallbackName: fallbackName);
    return bytes.length > _parseInBackgroundAbove ? Isolate.run(work) : Future.sync(work);
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
