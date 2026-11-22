import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'rudy_constants.dart';

/// Where the Rudy Map offline files live: `<applicationSupport>/rudy/`.
class RudyPaths {
  RudyPaths(this.root);

  /// Opens the default location under the app support directory.
  static Future<RudyPaths> open() async {
    final base = await getApplicationSupportDirectory();
    return RudyPaths(Directory('${base.path}/$relativeDirectory'));
  }

  /// Folder name under `BaseDirectory.applicationSupport` (for background_downloader).
  static const relativeDirectory = 'rudy';

  static const glyphsFolder = 'glyphs';

  /// The font folders the style needs; only these are unpacked from the fonts zip.
  static const fontFolders = ['Noto Sans Regular', 'Noto Sans Bold', 'Noto Sans Italic'];

  /// Temp name of the downloaded fonts zip (deleted after unpacking).
  static const fontsZipName = 'noto-sans.zip';

  final Directory root;

  File _f(String name) => File('${root.path}/$name');

  File get pmtiles => _f(rudyPmtilesFile);
  Directory get glyphs => Directory('${root.path}/$glyphsFolder');
  File get fontsZip => _f(fontsZipName);

  /// Written last; its presence means the install finished.
  File get readyMarker => _f('ready.json');

  /// Resolved mirror URL + fingerprint of the map download, used to resume.
  File get sourceInfo => _f('source.json');

  bool get isInstalled {
    try {
      return readyMarker.existsSync() &&
          pmtiles.existsSync() &&
          pmtiles.lengthSync() > 0 &&
          Directory('${glyphs.path}/${fontFolders.first}').existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Fingerprint stored in the ready marker, or null when unreadable.
  String? get installedFingerprint {
    try {
      final j = jsonDecode(readyMarker.readAsStringSync());
      return j is Map ? j['fingerprint'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAll() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
