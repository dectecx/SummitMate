import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/message.dart';
import 'converters/sync_status_converter.dart';
import 'trip_table.dart';

class MessagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().nullable().references(TripsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentId => text().nullable()();
  TextColumn get userId => text().withDefault(const Constant(''))();
  TextColumn get user => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant('🐻'))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter()).withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

extension MessageMapping on Message {
  MessagesTableCompanion toCompanion() {
    return MessagesTableCompanion.insert(
      id: id,
      tripId: Value(tripId),
      parentId: Value(parentId),
      userId: Value(userId),
      user: Value(user),
      avatar: Value(avatar),
      category: Value(category),
      content: Value(content),
      timestamp: timestamp,
      syncStatus: Value(syncStatus),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
