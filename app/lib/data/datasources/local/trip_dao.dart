import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/trip.dart';
import '../interfaces/i_trip_local_data_source.dart';
import '../../models/trip_table.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [TripsTable])
@LazySingleton(as: ITripLocalDataSource)
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin implements ITripLocalDataSource {
  TripDao(AppDatabase db) : super(db);

  @override
  Future<List<Trip>> getAllTrips() async {
    final query = select(tripsTable);
    final rows = await query.get();
    return rows
        .map(
          (row) => Trip(
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
          ),
        )
        .toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final query = select(tripsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

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
    // 實作：將所有 active 設為 false，再將指定的設為 true
    await update(tripsTable).write(const TripsTableCompanion(isActive: Value(false)));
    await (update(
      tripsTable,
    )..where((t) => t.id.equals(tripId))).write(const TripsTableCompanion(isActive: Value(true)));
  }

  @override
  Future<Trip?> getActiveTrip() async {
    final query = select(tripsTable)..where((t) => t.isActive.equals(true));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

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

  @override
  Future<void> clear() async {
    await delete(tripsTable).go();
  }
}
