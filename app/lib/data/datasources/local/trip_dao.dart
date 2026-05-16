import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/meal_plan_day.dart';
import '../interfaces/i_trip_local_data_source.dart';
import '../../models/trip_table.dart';
import '../../models/meal_plan_day_table.dart';
import '../../models/gear_item_table.dart';
import '../../models/itinerary_item_table.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [TripsTable, MealPlanDaysTable, GearItemsTable, ItineraryItemsTable])
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
            cloudSyncedAt: row.cloudSyncedAt,
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

    // 注意：這裡不主動 fetch mealPlanDays，由 caller (例如 TripRepository) 透過 getMealPlanDays() 獨立拉取，避免過多 JOIN 影響效能。

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
      cloudSyncedAt: row.cloudSyncedAt,
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
  Future<void> setActiveTrip(String userId, String tripId) async {
    // 實作：將該使用者的所有 active 設為 false，再將指定的設為 true
    await (update(
      tripsTable,
    )..where((t) => t.userId.equals(userId))).write(const TripsTableCompanion(isActive: Value(false)));
    await (update(tripsTable)..where((t) => t.id.equals(tripId) & t.userId.equals(userId))).write(
      const TripsTableCompanion(isActive: Value(true)),
    );
  }

  @override
  Future<Trip?> getActiveTrip(String userId) async {
    final query = select(tripsTable)..where((t) => t.isActive.equals(true) & t.userId.equals(userId));
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
      cloudSyncedAt: row.cloudSyncedAt,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }

  @override
  Future<void> clear() async {
    await delete(tripsTable).go();
    // Cascade delete on meal_plan_days_table should handle the related records
  }

  // ========== Meal Plan Day Operations ==========

  @override
  Future<List<MealPlanDay>> getMealPlanDays(String tripId) async {
    final query = select(mealPlanDaysTable)..where((t) => t.tripId.equals(tripId));
    final rows = await query.get();
    return rows
        .map((row) => MealPlanDay(id: row.id, name: row.name, linkedItineraryDay: row.linkedItineraryDay))
        .toList();
  }

  @override
  Future<void> saveMealPlanDay(MealPlanDay day, String tripId) async {
    await into(mealPlanDaysTable).insertOnConflictUpdate(day.toCompanion(tripId));
  }

  @override
  Future<void> deleteMealPlanDay(String dayId) async {
    await (delete(mealPlanDaysTable)..where((t) => t.id.equals(dayId))).go();
  }

  @override
  Future<void> replaceMealPlanDays(String tripId, List<MealPlanDay> days) async {
    await transaction(() async {
      await (delete(mealPlanDaysTable)..where((t) => t.tripId.equals(tripId))).go();
      for (final day in days) {
        await into(mealPlanDaysTable).insert(day.toCompanion(tripId));
      }
    });
  }

  @override
  Future<void> migrateTripId(String oldId, String newId) async {
    await transaction(() async {
      // 1. 取得舊行程資料
      final tripRow = await (select(tripsTable)..where((t) => t.id.equals(oldId))).getSingleOrNull();
      if (tripRow == null) return;

      // 2. 插入新 ID 的行程 (複本)
      // 注意：由於 id 是 PK，不能直接 update id，必須先 insert 新的再 delete 舊的
      await into(tripsTable).insert(
        TripsTableCompanion.insert(
          id: newId,
          userId: tripRow.userId,
          name: tripRow.name,
          description: Value(tripRow.description),
          startDate: tripRow.startDate,
          endDate: Value(tripRow.endDate),
          coverImage: Value(tripRow.coverImage),
          isActive: Value(tripRow.isActive),
          linkedEventId: Value(tripRow.linkedEventId),
          dayNames: Value(tripRow.dayNames),
          syncStatus: Value(tripRow.syncStatus),
          cloudSyncedAt: Value(tripRow.cloudSyncedAt),
          createdAt: tripRow.createdAt,
          createdBy: tripRow.createdBy,
          updatedAt: tripRow.updatedAt,
          updatedBy: tripRow.updatedBy,
        ),
      );

      // 3. 更新所有關聯表的 tripId
      await (update(
        itineraryItemsTable,
      )..where((t) => t.tripId.equals(oldId))).write(ItineraryItemsTableCompanion(tripId: Value(newId)));
      await (update(
        gearItemsTable,
      )..where((t) => t.tripId.equals(oldId))).write(GearItemsTableCompanion(tripId: Value(newId)));
      await (update(
        mealPlanDaysTable,
      )..where((t) => t.tripId.equals(oldId))).write(MealPlanDaysTableCompanion(tripId: Value(newId)));

      // 4. 刪除舊行程
      await (delete(tripsTable)..where((t) => t.id.equals(oldId))).go();
    });
  }
}
