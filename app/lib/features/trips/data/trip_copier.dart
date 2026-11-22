import '../../../core/db/app_database.dart';
import '../../library/data/template_repository.dart';
import '../domain/trip_logic.dart';
import 'itinerary_repository.dart';
import 'trip_repository.dart';

/// Copies a trip into a new one: the plan (dates shifted to the new start, nodes, main mountain, track) and the
/// copier's own gear and meals. Members, check-ins and packed ticks are not copied.
class TripCopier {
  TripCopier(this._trips, this._items, this._templates);
  final TripRepository _trips;
  final ItineraryRepository _items;
  final TemplateRepository _templates;

  /// Returns the id of the new trip.
  Future<String> copy(Trip source, {required String name, required DateTime start}) async {
    final length = source.endDate == null ? null : source.end.difference(source.start);
    final id = await _trips.create(
      name: name,
      start: start,
      end: length == null || length.inDays < 1 ? null : DateTime(start.year, start.month, start.day + length.inDays),
      description: source.description,
      mountainId: source.mountainId,
      track: source.track,
    );
    for (final n in await _items.watch(source.id).first) {
      await _items.add(id, dayIndex: n.dayIndex, name: n.name, estMinutes: n.estMinutes, altitude: n.altitude, distance: n.distance, lat: n.lat, lng: n.lng, note: n.note);
    }
    await _templates.applyToTrip(id, await _templates.itemsOfTrip(source.id));
    return id;
  }
}
