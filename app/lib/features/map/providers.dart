import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => const GeolocatorLocationService());

/// How the government base map's tiles are fetched: plain network, no on-device tile cache. Tests replace it.
final mapTileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(cachingProvider: const DisabledMapCachingProvider()),
);
