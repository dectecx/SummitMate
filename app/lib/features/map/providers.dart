import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'data/location_service.dart';
import 'data/offline_manager.dart';
import 'data/tile_cache.dart';

/// The tile cache; `main()` replaces it with the real one once the native database is open.
final tileCacheProvider = Provider<TileCache>((ref) => const NoTileCache());

final offlineManagerProvider = Provider((ref) => OfflineMapsManager(ref.watch(appDatabaseProvider), ref.watch(tileCacheProvider).downloader));

final offlineRegionsProvider = StreamProvider<List<OfflineRegion>>((ref) => ref.watch(offlineManagerProvider).watch());

final locationServiceProvider = Provider<LocationService>((ref) => const GeolocatorLocationService());
