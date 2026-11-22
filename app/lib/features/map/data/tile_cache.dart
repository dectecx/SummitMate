import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../domain/offline_regions.dart';
import 'background_tile_downloader.dart';
import 'offline_tile_store.dart';
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

/// Tile cache: tiles of downloaded regions are plain files (see [OfflineTileStore], filled by the background
/// downloader); everything else is fetched from the network and kept in a small flutter_map_tile_caching
/// 'browse' store, so tiles seen while panning also work offline for a while.
class FmtcTileCache implements TileCache {
  FmtcTileCache._(this._store, this.demStore) : downloader = BackgroundTileDownloader(_store, demStore);
  final OfflineTileStore _store;

  /// Where the elevation tiles of the 3D view are stored.
  final OfflineTileStore demStore;

  /// Where downloaded region tiles are stored.
  OfflineTileStore get store => _store;

  static const _browseStore = 'browse';

  /// Opens the on-device tile database and the background downloader. Call once before the app starts.
  static Future<FmtcTileCache> initialise() async {
    await FMTCObjectBoxBackend().initialise();
    final browse = const FMTCStore(_browseStore);
    if (!await browse.manage.ready) await browse.manage.create(maxLength: 8000);
    await BackgroundTileDownloader.configure();
    return FmtcTileCache._(await OfflineTileStore.open(), await OfflineTileStore.open(relativeRoot: OfflineTileStore.demRelativeRoot));
  }

  @override
  Widget buildTileLayer() => TileLayer(
    urlTemplate: nlscTileUrl,
    userAgentPackageName: appPackageName,
    maxNativeZoom: nlscMaxNativeZoom,
    tileProvider: OfflineFirstTileProvider(
      _store,
      FMTCTileProvider(stores: const {_browseStore: BrowseStoreStrategy.readUpdateCreate}),
    ),
  );

  @override
  final TileDownloader downloader;
}

/// Shows a downloaded tile from disk when there is one, otherwise defers to [_fallback] (cache, then network).
class OfflineFirstTileProvider extends TileProvider {
  OfflineFirstTileProvider(this._store, this._fallback);
  final OfflineTileStore _store;
  final TileProvider _fallback;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = _store.find(coordinates.z, coordinates.x, coordinates.y);
    return file != null ? FileImage(file) : _fallback.getImage(coordinates, options);
  }

  @override
  void dispose() {
    _fallback.dispose();
    super.dispose();
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
  Future<bool> isRunning(String regionId) async => false;

  @override
  Future<void> cancel(String regionId) async {}

  @override
  Future<void> deleteTiles(String regionId) async {}
}
