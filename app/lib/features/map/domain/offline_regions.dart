import 'dart:math' as math;

/// A rectangle on the map, in degrees.
class GeoBounds {
  const GeoBounds({required this.south, required this.west, required this.north, required this.east});
  final double south;
  final double west;
  final double north;
  final double east;

  /// A square around [lat], [lng] extending [halfSizeDeg] degrees in every direction.
  factory GeoBounds.around(double lat, double lng, double halfSizeDeg) =>
      GeoBounds(south: lat - halfSizeDeg, west: lng - halfSizeDeg, north: lat + halfSizeDeg, east: lng + halfSizeDeg);
}

/// What can be downloaded for offline use.
class OfflineRegionDef {
  const OfflineRegionDef({required this.id, required this.name, required this.description, required this.bounds, required this.minZoom, required this.maxZoom});
  final String id;
  final String name;
  final String description;
  final GeoBounds bounds;
  final int minZoom;
  final int maxZoom;

  int get estimatedTiles => countTiles(bounds, minZoom, maxZoom);
  double get estimatedBytes => estimatedTiles * averageTileBytes;
}

/// Average size of an NLSC tile, measured on a handful of samples (13 to 33 KB each).
const averageTileBytes = 25 * 1024.0;

/// The highest zoom with real map detail on the NLSC open-data layer (z16 is only an enlarged z15).
const nlscMaxNativeZoom = 15;

/// The whole island at low zoom (about 1,600 tiles): enough to find your way around.
const taiwanBase = OfflineRegionDef(
  id: 'taiwan-base',
  name: '全台底圖',
  description: '全台灣的低倍率地圖，用來概覽與定位',
  bounds: GeoBounds(south: 21.8, west: 119.9, north: 25.4, east: 122.1),
  minZoom: 8,
  maxZoom: 12,
);

OfflineRegionDef _area(String id, String name, String description, double lat, double lng, double half) =>
    OfflineRegionDef(id: id, name: name, description: description, bounds: GeoBounds.around(lat, lng, half), minZoom: 10, maxZoom: nlscMaxNativeZoom);

/// Popular mountain areas, centred on the peaks of the mountain list (so they match the data in the app),
/// each about 25 km across and downloaded in detail (z10 to z15).
final popularRegions = <OfflineRegionDef>[
  _area('yushan', '玉山', '玉山主峰、東峰、南峰、北峰', 23.47, 120.96, 0.12),
  _area('xueba', '雪山與雪霸', '雪山、大霸尖山、品田山', 24.40, 121.25, 0.12),
  _area('nanhu', '南湖大山', '南湖大山、中央尖山', 24.34, 121.43, 0.12),
  _area('hehuan-qilai', '合歡與奇萊', '合歡山群、奇萊主北', 24.12, 121.30, 0.12),
  _area('nenggao', '能高山', '能高山、能高山南峰', 23.98, 121.27, 0.10),
  _area('xiuguluan', '秀姑巒與八通關', '秀姑巒山、馬博拉斯山、大水窟山', 23.50, 121.05, 0.10),
  _area('jiaming', '嘉明湖與向陽', '向陽山、三叉山、嘉明湖一帶', 23.29, 121.00, 0.10),
  _area('guanshan', '關山與卑南', '關山、小關山、卑南主山', 23.15, 120.89, 0.15),
  _area('beidawu', '北大武山', '北大武山', 22.63, 120.76, 0.08),
];

/// Everything that can be downloaded, the island first.
final allOfflineRegions = <OfflineRegionDef>[taiwanBase, ...popularRegions];

OfflineRegionDef? offlineRegionById(String id) {
  for (final r in allOfflineRegions) {
    if (r.id == id) return r;
  }
  return null;
}

/// The detailed area that contains a point, or null when no area covers it (the island base map still does).
/// When several overlap, the one whose centre is closest wins.
OfflineRegionDef? offlineRegionFor(double lat, double lng) {
  OfflineRegionDef? best;
  var bestDistance = double.infinity;
  for (final r in popularRegions) {
    final b = r.bounds;
    if (lat < b.south || lat > b.north || lng < b.west || lng > b.east) continue;
    final d = math.pow((b.south + b.north) / 2 - lat, 2) + math.pow((b.west + b.east) / 2 - lng, 2);
    if (d < bestDistance) {
      best = r;
      bestDistance = d.toDouble();
    }
  }
  return best;
}

/// Number of tiles covering [bounds] for zoom levels [minZoom] to [maxZoom] (standard web-mercator tile grid).
int countTiles(GeoBounds bounds, int minZoom, int maxZoom) {
  var total = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final x0 = _tileX(bounds.west, z), x1 = _tileX(bounds.east, z);
    final y0 = _tileY(bounds.north, z), y1 = _tileY(bounds.south, z);
    total += (x1 - x0 + 1) * (y1 - y0 + 1);
  }
  return total;
}

/// One map tile in the standard web-mercator grid.
typedef TileId = ({int z, int x, int y});

/// Every tile covering [bounds] for zoom levels [minZoom] to [maxZoom].
Iterable<TileId> tilesFor(GeoBounds bounds, int minZoom, int maxZoom) sync* {
  for (var z = minZoom; z <= maxZoom; z++) {
    final x0 = _tileX(bounds.west, z), x1 = _tileX(bounds.east, z);
    final y0 = _tileY(bounds.north, z), y1 = _tileY(bounds.south, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        yield (z: z, x: x, y: y);
      }
    }
  }
}

int _tileX(double lng, int z) => ((lng + 180) / 360 * (1 << z)).floor();

int _tileY(double lat, int z) {
  final rad = lat * math.pi / 180;
  return ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * (1 << z)).floor();
}

/// "42 MB" / "1.3 GB" style size for people.
String formatBytes(double bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
}
