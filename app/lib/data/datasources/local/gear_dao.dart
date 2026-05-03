import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/gear_item.dart';
import '../interfaces/i_gear_local_data_source.dart';
import '../../models/gear_item_table.dart';

part 'gear_dao.g.dart';

@LazySingleton(as: IGearLocalDataSource)
@DriftAccessor(tables: [GearItemsTable])
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
  GearItem? getByKey(dynamic key) => null; // Deprecated

  @override
  Future<GearItem?> getById(String id) async {
    final query = select(gearItemsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<int> addItem(GearItem item) async {
    return await into(gearItemsTable).insert(item.toCompanion());
  }

  @override
  Future<void> updateItem(GearItem item) async {
    await update(gearItemsTable).replace(item.toCompanion());
  }

  @override
  Future<void> deleteByKey(dynamic key) async {
    if (key is String) {
      await deleteById(key);
    }
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

  @override
  Stream<List<GearItem>> watch() {
    return select(gearItemsTable).watch().map((rows) => rows.map((row) => _mapToDomain(row)).toList());
  }

  GearItem _mapToDomain(GearItemsTableData row) {
    return GearItem(
      id: row.id,
      tripId: row.tripId,
      name: row.name,
      category: row.category,
      weight: row.weight,
      quantity: row.quantity,
      isChecked: row.isChecked,
      orderIndex: row.orderIndex,
      libraryItemId: row.libraryItemId,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }
}
