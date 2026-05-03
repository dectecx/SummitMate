import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/database/app_database.dart';
import '../datasources/interfaces/i_gear_library_local_data_source.dart';
import '../models/gear_library_item_table.dart';
import '../../domain/entities/gear_library_item.dart';

part 'gear_library_dao.g.dart';

@LazySingleton(as: IGearLibraryLocalDataSource)
@DriftAccessor(tables: [GearLibraryItemsTable])
class GearLibraryDao extends DatabaseAccessor<AppDatabase>
    with _$GearLibraryDaoMixin
    implements IGearLibraryLocalDataSource {
  GearLibraryDao(AppDatabase db) : super(db);

  @override
  Future<List<GearLibraryItem>> getAllItems() async {
    final rows = await select(gearLibraryItemsTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<GearLibraryItem?> getById(String id) async {
    final query = select(gearLibraryItemsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> saveItem(GearLibraryItem item) async {
    await into(gearLibraryItemsTable).insertOnConflictUpdate(item.toCompanion());
  }

  @override
  Future<void> saveItems(List<GearLibraryItem> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(gearLibraryItemsTable, items.map((e) => e.toCompanion()).toList());
    });
  }

  @override
  Future<void> deleteItem(String id) async {
    await (delete(gearLibraryItemsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clear() async {
    await delete(gearLibraryItemsTable).go();
  }

  GearLibraryItem _mapToDomain(GearLibraryItemsTableData row) {
    return GearLibraryItem(
      id: row.id,
      userId: row.userId,
      name: row.name,
      weight: row.weight,
      category: row.category,
      notes: row.notes,
      isArchived: row.isArchived,
      syncStatus: row.syncStatus,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }
}
