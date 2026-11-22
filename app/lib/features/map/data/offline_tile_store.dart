import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiles of downloaded regions, stored as plain files: `<root>/<region>/<z>/<x>/<y>.tile`. Files rather than a
/// database so the system's background transfer service can write them while the app is not running.
class OfflineTileStore {
  OfflineTileStore(this.root) {
    if (root.existsSync()) {
      for (final e in root.listSync()) {
        if (e is Directory) _regions.add(e.uri.pathSegments.where((s) => s.isNotEmpty).last);
      }
    }
  }

  /// Where downloaded tiles live, relative to the app support directory (the downloader's base directory).
  static const relativeRoot = 'offline_tiles';

  final Directory root;
  final _regions = <String>{};

  static Future<OfflineTileStore> open() async {
    final support = await getApplicationSupportDirectory();
    return OfflineTileStore(Directory('${support.path}/$relativeRoot'));
  }

  /// Directory and file name of a tile, for the downloader (relative to the app support directory).
  static String tileDirectory(String regionId, int z, int x) => '$relativeRoot/$regionId/$z/$x';
  static String tileFilename(int y) => '$y.tile';

  File tileFile(String regionId, int z, int x, int y) => File('${root.path}/$regionId/$z/$x/$y.tile');

  /// Called when a download starts, so tiles that arrive are found by the map straight away.
  void register(String regionId) => _regions.add(regionId);

  /// The stored tile for these coordinates from any region, or null. Synchronous: it runs while the map paints.
  File? find(int z, int x, int y) {
    for (final id in _regions) {
      final f = tileFile(id, z, x, y);
      if (f.existsSync()) return f;
    }
    return null;
  }

  Future<void> delete(String regionId) async {
    _regions.remove(regionId);
    final dir = Directory('${root.path}/$regionId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
