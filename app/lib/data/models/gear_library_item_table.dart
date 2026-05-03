import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/gear_library_item.dart';
import '../../domain/enums/sync_status.dart';
import 'converters/sync_status_converter.dart';

class GearLibraryItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get weight => real()();
  TextColumn get category => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().map(const SyncStatusConverter()).withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

extension GearLibraryItemMapping on GearLibraryItem {
  GearLibraryItemsTableCompanion toCompanion() {
    return GearLibraryItemsTableCompanion.insert(
      id: id,
      userId: userId,
      name: name,
      weight: weight,
      category: category,
      notes: Value(notes),
      isArchived: Value(isArchived),
      syncStatus: Value(syncStatus),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
