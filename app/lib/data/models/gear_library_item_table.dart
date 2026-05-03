import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/gear_library_item.dart';

import '../../domain/enums/sync_status.dart';

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

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();
  @override
  SyncStatus fromSql(String fromDb) =>
      SyncStatus.values.firstWhere((e) => e.name == fromDb, orElse: () => SyncStatus.synced);
  @override
  String toSql(SyncStatus value) => value.name;
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
