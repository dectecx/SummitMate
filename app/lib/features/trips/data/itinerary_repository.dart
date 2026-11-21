// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// Itinerary nodes (trailhead, hut, peak ...) of a trip.
class ItineraryRepository {
  ItineraryRepository(this._db, this._outbox, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  Stream<List<ItineraryItem>> watch(String tripId) => (_db.select(_db.itineraryItems)..where((i) => i.tripId.equals(tripId))).watch();

  Future<String> add(
    String tripId, {
    required int dayIndex,
    required String name,
    int? estMinutes,
    int altitude = 0,
    double distance = 0,
    double? lat,
    double? lng,
    String note = '',
  }) async {
    final id = _uuid.v7();
    await _db.transaction(() async {
      await _db.into(_db.itineraryItems).insert(
        ItineraryItemsCompanion.insert(
          id: id,
          tripId: tripId,
          dayIndex: Value(dayIndex),
          name: Value(name),
          estMinutes: Value(estMinutes),
          altitude: Value(altitude),
          distance: Value(distance),
          lat: Value(lat),
          lng: Value(lng),
          note: Value(note),
        ),
      );
      await _outbox.upsert(
        'itinerary_items',
        id,
        {
          'trip_id': tripId,
          'day_index': dayIndex,
          'name': name,
          'est_minutes': estMinutes,
          'altitude': altitude,
          'distance': distance,
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
          'note': note,
        },
        isCreate: true,
      );
    });
    return id;
  }

  /// Changes only the fields that are given. Pass `Value(null)` to clear the time.
  Future<void> update(
    String id, {
    int? dayIndex,
    String? name,
    Value<int?> estMinutes = const Value.absent(),
    int? altitude,
    double? distance,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    String? note,
    Value<DateTime?> checkedInAt = const Value.absent(),
  }) async {
    final patch = <String, Object?>{
      'day_index': ?dayIndex,
      'name': ?name,
      if (estMinutes.present) 'est_minutes': estMinutes.value,
      'altitude': ?altitude,
      'distance': ?distance,
      if (lat.present) 'lat': lat.value,
      if (lng.present) 'lng': lng.value,
      'note': ?note,
      if (checkedInAt.present) 'checked_in_at': checkedInAt.value,
    };
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.itineraryItems)..where((i) => i.id.equals(id))).write(
        ItineraryItemsCompanion(
          dayIndex: Value.absentIfNull(dayIndex),
          name: Value.absentIfNull(name),
          estMinutes: estMinutes,
          altitude: Value.absentIfNull(altitude),
          distance: Value.absentIfNull(distance),
          lat: lat,
          lng: lng,
          note: Value.absentIfNull(note),
          checkedInAt: checkedInAt,
        ),
      );
      await _outbox.upsert('itinerary_items', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('itinerary_items', id);
    await (_db.delete(_db.itineraryItems)..where((i) => i.id.equals(id))).go();
  });
}
