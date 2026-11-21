import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../domain/offline_regions.dart';
import 'tile_downloader.dart';

/// NLSC (內政部國土測繪中心) open-data e-map with contour lines. Note the z/y/x order.
const nlscTileUrl = 'https://wmts.nlsc.gov.tw/wmts/EMAP5_OPENDATA/default/GoogleMapsCompatible/{z}/{y}/{x}';
const appPackageName = 'com.declab.summitmate';

/// The map's tile layer plus the offline downloader that fills the same cache.
abstract interface class TileCache {
  /// The layer to put inside a `FlutterMap` (reads downloaded regions, falls back to the network).
  Widget buildTileLayer();
  TileDownloader get downloader;
}

/// Tile cache backed by flutter_map_tile_caching: one cache store per downloaded region, so deleting a
/// region removes only the tiles that no other region needs, plus a small 'browse' store for tiles seen
/// while panning.
class FmtcTileCache implements TileCache {
  FmtcTileCache._();

  static const _browseStore = 'browse';

  /// Opens the on-device tile database. Call once before the app starts.
  static Future<FmtcTileCache> initialise() async {
    await FMTCObjectBoxBackend().initialise();
    final browse = const FMTCStore(_browseStore);
    if (!await browse.manage.ready) await browse.manage.create(maxLength: 8000);
    return FmtcTileCache._();
  }

  @override
  Widget buildTileLayer() => TileLayer(
    urlTemplate: nlscTileUrl,
    userAgentPackageName: appPackageName,
    maxNativeZoom: nlscMaxNativeZoom,
    tileProvider: FMTCTileProvider(
      stores: const {_browseStore: BrowseStoreStrategy.readUpdateCreate},
      otherStoresStrategy: BrowseStoreStrategy.read,
    ),
  );

  @override
  final TileDownloader downloader = FmtcTileDownloader();
}

class FmtcTileDownloader implements TileDownloader {
  static FMTCStore _store(String regionId) => FMTCStore('region-$regionId');

  @override
  Stream<DownloadUpdate> download(OfflineRegionDef region) async* {
    final store = _store(region.id);
    if (!await store.manage.ready) await store.manage.create();
    final b = region.bounds;
    final downloadable = RectangleRegion(LatLngBounds(LatLng(b.south, b.west), LatLng(b.north, b.east))).toDownloadable(
      minZoom: region.minZoom,
      maxZoom: region.maxZoom,
      options: TileLayer(urlTemplate: nlscTileUrl, userAgentPackageName: appPackageName, maxNativeZoom: nlscMaxNativeZoom),
    );
    final result = store.download.startForeground(
      region: downloadable,
      parallelThreads: 3,
      rateLimit: 25, // tiles per second: polite to a public government server
      skipExistingTiles: true, // a retry only fetches what is missing
      instanceId: region.id,
    );
    DownloadProgress? last;
    await for (final p in result.downloadProgress) {
      last = p;
      // FMTC reports sizes in KiB.
      yield DownloadUpdate(done: p.attemptedTilesCount, total: p.maxTilesCount, bytes: p.successfulTilesSize * 1024);
    }
    final failed = last?.failedTilesCount ?? 0;
    if (failed > 0) throw StateError('$failed 張圖磚下載失敗');
  }

  @override
  Future<void> cancel(String regionId) => _store(regionId).download.cancel(instanceId: regionId);

  @override
  Future<void> deleteTiles(String regionId) async {
    final store = _store(regionId);
    if (await store.manage.ready) await store.manage.delete();
  }
}

/// Used where the native tile database is not available (widget tests): no layer, nothing to download.
class NoTileCache implements TileCache {
  const NoTileCache();

  @override
  Widget buildTileLayer() => const SizedBox.shrink();

  @override
  TileDownloader get downloader => const _NoDownloader();
}

class _NoDownloader implements TileDownloader {
  const _NoDownloader();

  @override
  Stream<DownloadUpdate> download(OfflineRegionDef region) => const Stream.empty();

  @override
  Future<void> cancel(String regionId) async {}

  @override
  Future<void> deleteTiles(String regionId) async {}
}
