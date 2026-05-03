import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/gear_item.dart';

// TODO: 確認是否需要建立 Foreign Key 關聯 TripTable
class GearItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get name => text()();
  RealColumn get weight => real()();
  TextColumn get category => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get libraryItemId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

extension GearItemMapping on GearItem {
  GearItemsTableCompanion toCompanion() {
    return GearItemsTableCompanion.insert(
      id: id,
      tripId: tripId,
      name: name,
      weight: weight,
      category: category,
      isChecked: Value(isChecked),
      orderIndex: Value(orderIndex),
      quantity: Value(quantity),
      libraryItemId: Value(libraryItemId),
      createdAt: Value(createdAt),
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
    );
  }
}
