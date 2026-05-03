import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/database/app_database.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../models/trip_table.dart';
import '../../domain/entities/trip.dart';

part 'trip_dao.g.dart';

@LazySingleton(as: ITripLocalDataSource)
@DriftAccessor(tables: [TripsTable])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin implements ITripLocalDataSource {
  TripDao(AppDatabase db) : super(db);

  @override
  Future<List<Trip>> getAllTrips() async {
    final rows = await select(tripsTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final query = select(tripsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> addTrip(Trip trip) async {
    await into(tripsTable).insert(trip.toCompanion());
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await update(tripsTable).replace(trip.toCompanion());
  }

  @override
  Future<void> deleteTrip(String id) async {
    await (delete(tripsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    await batch((batch) {
      batch.update(tripsTable, const TripsTableCompanion(isActive: Value(false)));
      batch.update(tripsTable, const TripsTableCompanion(isActive: Value(true)), where: (t) => t.id.equals(tripId));
    });
  }

  @override
  Future<Trip?> getActiveTrip() async {
    final query = select(tripsTable)..where((t) => t.isActive.equals(true));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> clear() async {
    await delete(tripsTable).go();
  }

  Trip _mapToDomain(TripsTableData row) {
    return Trip(
      id: row.id,
      userId: row.userId,
      name: row.name,
      description: row.description,
      startDate: row.startDate,
      endDate: row.endDate,
      coverImage: row.coverImage,
      isActive: row.isActive,
      linkedEventId: row.linkedEventId,
      dayNames: row.dayNames,
      syncStatus: row.syncStatus,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }
}
