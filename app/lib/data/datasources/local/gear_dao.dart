import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/gear_item.dart';
import '../interfaces/i_gear_local_data_source.dart';
import '../../models/gear_item_table.dart';

part 'gear_dao.g.dart';

@DriftAccessor(tables: [GearItemsTable])
@LazySingleton(as: IGearLocalDataSource)
class GearDao extends DatabaseAccessor<AppDatabase> with _$GearDaoMixin implements IGearLocalDataSource {
  GearDao(AppDatabase db) : super(db);

  @override
  Future<List<GearItem>> getAll() async {
    final rows = await select(gearItemsTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<List<GearItem>> getByTripId(String tripId) async {
    final query = select(gearItemsTable)..where((t) => t.tripId.equals(tripId));
    final rows = await query.get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<List<GearItem>> getByCategory(String category) async {
    final query = select(gearItemsTable)..where((t) => t.category.equals(category));
    final rows = await query.get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<List<GearItem>> getUnchecked() async {
    final query = select(gearItemsTable)..where((t) => t.isChecked.equals(false));
    final rows = await query.get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<GearItem?> getById(String id) async {
    final query = select(gearItemsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<int> add(GearItem item) async {
    await into(gearItemsTable).insert(item.toCompanion());
    return 0; // Drift doesn't return int key for non-auto-increment text PK
  }

  @override
  Future<void> update(GearItem item) async {
    await update(gearItemsTable).replace(item.toCompanion());
  }

  @override
  Future<void> deleteById(String id) async {
    await (delete(gearItemsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clearByTripId(String tripId) async {
    await (delete(gearItemsTable)..where((t) => t.tripId.equals(tripId))).go();
  }

  @override
  Future<void> clearAll() async {
    await delete(gearItemsTable).go();
  }

  // TODO: Implement watch() for Drift stream
  @override
  Stream<List<GearItem>> watch() {
    return select(gearItemsTable).watch().map((rows) => rows.map((row) => _mapToDomain(row)).toList());
  }

  GearItem _mapToDomain(GearItemsTableData row) {
    return GearItem(
      id: row.id,
      tripId: row.tripId,
      name: row.name,
      weight: row.weight,
      category: row.category,
      isChecked: row.isChecked,
      orderIndex: row.orderIndex,
      quantity: row.quantity,
      libraryItemId: row.libraryItemId,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }

  @override
  GearItem? getByKey(key) => throw UnimplementedError('Hive key usage is deprecated');

  @override
  Future<void> delete(key) => throw UnimplementedError('Hive key usage is deprecated');
}
