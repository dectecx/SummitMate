// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/trip_logic.dart';

/// Reads and writes trips. Every write goes to the local database and the outbox in one
/// transaction (the UI never waits for the network).
class TripRepository {
  TripRepository(this._db, this._outbox, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  Stream<List<Trip>> watchAll() => _db.select(_db.trips).watch();

  Stream<Trip?> watch(String id) => (_db.select(_db.trips)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<TripMember>> watchMembers(String tripId) => (_db.select(_db.tripMembers)..where((m) => m.tripId.equals(tripId))).watch();

  /// Creates a trip and returns its id.
  Future<String> create({required String name, required DateTime start, DateTime? end, String description = ''}) async {
    final id = _uuid.v7();
    final endDate = end != null && end.isAfter(start) ? end : null;
    await _db.transaction(() async {
      await _db.into(_db.trips).insert(
        TripsCompanion.insert(
          id: id,
          name: name,
          description: Value(description),
          startDate: formatDate(start),
          endDate: Value(endDate == null ? null : formatDate(endDate)),
        ),
      );
      await _outbox.upsert(
        'trips',
        id,
        {'name': name, 'description': description, 'start_date': formatDate(start), 'end_date': endDate == null ? null : formatDate(endDate)},
        isCreate: true,
      );
    });
    return id;
  }

  /// Changes only the fields that are given.
  Future<void> update(
    String id, {
    String? name,
    String? description,
    DateTime? start,
    Value<DateTime?> end = const Value.absent(),
  }) async {
    final patch = <String, Object?>{
      'name': ?name,
      'description': ?description,
      if (start != null) 'start_date': formatDate(start),
      if (end.present) 'end_date': end.value == null ? null : formatDate(end.value!),
    };
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.trips)..where((t) => t.id.equals(id))).write(
        TripsCompanion(
          name: Value.absentIfNull(name),
          description: Value.absentIfNull(description),
          startDate: start == null ? const Value.absent() : Value(formatDate(start)),
          endDate: end.present ? Value(end.value == null ? null : formatDate(end.value!)) : const Value.absent(),
        ),
      );
      await _outbox.upsert('trips', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('trips', id); // before the row goes: it needs the children to drop their pending work
    await (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
  });

  /// Adds the bundled example trip (kept on this device only, never uploaded) and returns its id.
  Future<String> createSample({DateTime? today}) async {
    final id = _uuid.v7();
    final t = today ?? DateTime.now();
    final start = DateTime(t.year, t.month, t.day + 14);
    await _db.transaction(() async {
      await _db.into(_db.trips).insert(
        TripsCompanion.insert(
          id: id,
          name: '範例：向陽山屋兩天一夜',
          description: const Value('這是範例行程，只存在這支手機，可以隨意修改或刪除。'),
          startDate: formatDate(start),
          endDate: Value(formatDate(DateTime(start.year, start.month, start.day + 1))),
          isSample: const Value(true),
        ),
      );
      Future<void> item(int day, String name, int minutes, int altitude, double km, {String note = ''}) =>
          _db.into(_db.itineraryItems).insert(
            ItineraryItemsCompanion.insert(
              id: _uuid.v7(),
              tripId: id,
              dayIndex: Value(day),
              name: Value(name),
              estMinutes: Value(minutes),
              altitude: Value(altitude),
              distance: Value(km),
              note: Value(note),
            ),
          );
      await item(1, '向陽登山口', 7 * 60, 2300, 0, note: '出發前請確認入山證與天氣。');
      await item(1, '黑水塘', 9 * 60 + 30, 2700, 2.1);
      await item(1, '向陽山屋', 12 * 60, 2850, 2.2, note: '午餐、整理裝備。');
      await item(2, '向陽山屋', 6 * 60, 2850, 0);
      await item(2, '向陽登山口', 10 * 60, 2300, 4.3, note: '下山，記得帶走垃圾。');
    });
    return id;
  }
}
