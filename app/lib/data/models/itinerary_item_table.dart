import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/itinerary_item.dart';

// TODO: 確認是否需要建立 Foreign Key 關聯 TripTable
class ItineraryItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get day => text()();
  TextColumn get name => text()();
  TextColumn get estTime => text()();
  DateTimeColumn get actualTime => dateTime().nullable()();
  IntColumn get altitude => integer().withDefault(const Constant(0))();
  RealColumn get distance => real().withDefault(const Constant(0.0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get imageAsset => text().nullable()();
  BoolColumn get isCheckedIn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get checkedInAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

extension ItineraryItemMapping on ItineraryItem {
  ItineraryItemsTableCompanion toCompanion() {
    return ItineraryItemsTableCompanion.insert(
      id: id,
      tripId: tripId,
      day: day,
      name: name,
      estTime: estTime,
      actualTime: Value(actualTime),
      altitude: Value(altitude),
      distance: Value(distance),
      note: Value(note),
      imageAsset: Value(imageAsset),
      isCheckedIn: Value(isCheckedIn),
      checkedInAt: Value(checkedInAt),
      createdAt: Value(createdAt),
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
    );
  }
}
