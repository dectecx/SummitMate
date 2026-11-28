import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gpx/domain/track_route.dart';
import '../gpx/providers.dart';
import '../trips/domain/track_codec.dart';
import '../trips/providers.dart';
import 'data/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => const GeolocatorLocationService());

/// How the government base map's tiles are fetched: plain network, no on-device tile cache. Tests replace it.
final mapTileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(cachingProvider: const DisabledMapCachingProvider()),
);

/// Which route the map shows: one attached to a trip, or one of the saved GPX files.
typedef MapRouteRef = ({bool fromTrip, String id});

class MapRoute extends Notifier<MapRouteRef?> {
  @override
  MapRouteRef? build() => null;
  void showTrip(String tripId) => state = (fromTrip: true, id: tripId);
  void showSaved(String routeId) => state = (fromTrip: false, id: routeId);
  void clear() => state = null;
}

final mapRouteProvider = NotifierProvider<MapRoute, MapRouteRef?>(MapRoute.new);

/// The chosen route's points, or null when none is chosen or it is gone.
final shownRouteProvider = FutureProvider<TrackRoute?>((ref) async {
  final chosen = ref.watch(mapRouteProvider);
  if (chosen == null) return null;
  if (chosen.fromTrip) {
    final trip = ref.watch(tripProvider(chosen.id)).value;
    final points = decodeTrack(trip?.track);
    return points.length < 2 ? null : TrackRoute(name: trip!.name, points: points);
  }
  // follows renames and deletions
  ref.watch(gpxRoutesProvider.select((r) => r.value?.where((x) => x.id == chosen.id).firstOrNull?.name));
  return ref.watch(gpxLibraryProvider).load(chosen.id);
});
