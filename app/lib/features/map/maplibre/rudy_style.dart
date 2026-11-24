import 'package:flutter/services.dart';

/// The Rudy Map style (from https://github.com/alpha-rudy/taiwan-topo, `styles/pmtiles_style/style.json`) with
/// the sprite removed until the author publishes it. Files are referenced by placeholders.
const rudyStyleAsset = 'assets/rudy/style_template.json';

/// A style string for MapLibre that reads the map file and the fonts from the app's own storage.
Future<String> buildRudyStyle({required String pmtilesPath, required String glyphsDir, AssetBundle? bundle}) async {
  final template = await (bundle ?? rootBundle).loadString(rudyStyleAsset);
  return fillRudyStyle(template, pmtilesPath: pmtilesPath, glyphsDir: glyphsDir);
}

/// Pure part of [buildRudyStyle]. Paths are written as file URIs (spaces and non-ASCII characters escaped).
String fillRudyStyle(String template, {required String pmtilesPath, required String glyphsDir}) {
  return template.replaceAll('{{PMTILES}}', Uri.file(pmtilesPath).toString()).replaceAll('{{GLYPHS}}', Uri.file(glyphsDir).toString());
}
