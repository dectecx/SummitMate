import '../domain/gpx_trip.dart';
import 'itinerary_repository.dart';
import 'trip_repository.dart';

/// Creates the trip, its nodes and its stored track from a parsed GPX file and returns the trip id.
Future<String> importGpxTrip(TripRepository trips, ItineraryRepository items, ImportedTrip t, {String? mountainId}) async {
  final end = t.dayCount > 1 ? DateTime(t.start.year, t.start.month, t.start.day + t.dayCount - 1) : null;
  final id = await trips.create(
    name: t.name,
    start: t.start,
    end: end,
    mountainId: mountainId,
    track: t.track.length >= 2 ? encodeTrack(t.track) : null,
  );
  for (final n in t.nodes) {
    await items.add(id, dayIndex: n.dayIndex, name: n.name, estMinutes: n.estMinutes, altitude: n.altitude, distance: n.distanceKm, lat: n.lat, lng: n.lng);
  }
  return id;
}
