import 'dart:convert';

import 'package:flutter/services.dart';

/// The Rudy Map style (from https://github.com/alpha-rudy/taiwan-topo, `styles/pmtiles_style/style.json`) with
/// the sprite removed until the author publishes it. Files are referenced by placeholders.
const rudyStyleAsset = 'assets/rudy/style_template.json';

/// A style string for MapLibre that reads the map file, the fonts and (when installed) the elevation tiles from the
/// app's own storage. Without [demDir] the hillshade and 3D terrain are left out.
Future<String> buildRudyStyle({required String pmtilesPath, required String glyphsDir, String? demDir, AssetBundle? bundle}) async {
  final template = await (bundle ?? rootBundle).loadString(rudyStyleAsset);
  return fillRudyStyle(template, pmtilesPath: pmtilesPath, glyphsDir: glyphsDir, demDir: demDir);
}

/// Pure part of [buildRudyStyle]. Paths are written as file URIs (spaces and non-ASCII characters escaped).
String fillRudyStyle(String template, {required String pmtilesPath, required String glyphsDir, String? demDir}) {
  var text = template.replaceAll('{{PMTILES}}', Uri.file(pmtilesPath).toString()).replaceAll('{{GLYPHS}}', Uri.file(glyphsDir).toString());
  if (demDir != null) return text.replaceAll('{{DEM}}', Uri.file(demDir).toString());

  // No elevation data: drop the DEM source, everything drawn from it and the terrain.
  final style = jsonDecode(text) as Map<String, dynamic>;
  (style['sources'] as Map).remove('dem');
  (style['layers'] as List).removeWhere((l) => (l as Map)['source'] == 'dem' || l['type'] == 'hillshade');
  style.remove('terrain');
  text = jsonEncode(style);
  return text;
}
