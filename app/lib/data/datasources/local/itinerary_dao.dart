import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../interfaces/i_itinerary_local_data_source.dart';
import '../../models/itinerary_item_table.dart';

part 'itinerary_dao.g.dart';

@DriftAccessor(tables: [ItineraryItemsTable])
@LazySingleton(as: IItineraryLocalDataSource)
class ItineraryDao extends DatabaseAccessor<AppDatabase> with _$ItineraryDaoMixin implements IItineraryLocalDataSource {
  ItineraryDao(AppDatabase db) : super(db);

  @override
  Future<List<ItineraryItem>> getAll() async {
    final rows = await select(itineraryItemsTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<List<ItineraryItem>> getByTripId(String tripId) async {
    final query = select(itineraryItemsTable)..where((t) => t.tripId.equals(tripId));
    final rows = await query.get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<ItineraryItem?> getById(String id) async {
    final query = select(itineraryItemsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> add(ItineraryItem item) async {
    await into(itineraryItemsTable).insert(item.toCompanion());
  }

  @override
  Future<void> update(ItineraryItem item) async {
    await update(itineraryItemsTable).replace(item.toCompanion());
  }

  @override
  Future<void> deleteById(String id) async {
    await (delete(itineraryItemsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clearByTripId(String tripId) async {
    await (delete(itineraryItemsTable)..where((t) => t.tripId.equals(tripId))).go();
  }

  @override
  Future<void> clear() async {
    await delete(itineraryItemsTable).go();
  }

  @override
  Stream<List<ItineraryItem>> watch() {
    return select(itineraryItemsTable).watch().map((rows) => rows.map((row) => _mapToDomain(row)).toList());
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    // TODO: Implement metadata storage for sync times in AppDatabase if needed
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return null; // TODO: Implement metadata retrieval
  }

  ItineraryItem _mapToDomain(ItineraryItemsTableData row) {
    return ItineraryItem(
      id: row.id,
      tripId: row.tripId,
      day: row.day,
      name: row.name,
      estTime: row.estTime,
      actualTime: row.actualTime,
      altitude: row.altitude,
      distance: row.distance,
      note: row.note,
      imageAsset: row.imageAsset,
      isCheckedIn: row.isCheckedIn,
      checkedInAt: row.checkedInAt,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }

  @override
  ItineraryItem? getByKey(key) => throw UnimplementedError();

  @override
  Future<void> delete(key) => throw UnimplementedError();
}
