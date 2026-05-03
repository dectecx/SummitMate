import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/trip.dart';
import '../../domain/enums/sync_status.dart';
import 'converters/sync_status_converter.dart';

export '../../domain/enums/sync_status.dart';

// TODO: 確認是否需要建立 Foreign Key 關聯 userId, linkedEventId 等
class TripsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get coverImage => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get linkedEventId => text().nullable()();

  // TODO: 確認 List<String> 序列化為 JSON String 是否為最佳實踐，或該另開關聯表
  TextColumn get dayNames => text().map(const ListStringTypeConverter()).withDefault(const Constant('[]'))();

  TextColumn get syncStatus => text().map(const SyncStatusConverter()).withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ListStringTypeConverter extends TypeConverter<List<String>, String> {
  const ListStringTypeConverter();

  @override
  List<String> fromSql(String fromDb) {
    return List<String>.from(json.decode(fromDb));
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

extension TripMapping on Trip {
  TripsTableCompanion toCompanion() {
    return TripsTableCompanion.insert(
      id: id,
      userId: userId,
      name: name,
      description: Value(description),
      startDate: startDate,
      endDate: Value(endDate),
      coverImage: Value(coverImage),
      isActive: Value(isActive),
      linkedEventId: Value(linkedEventId),
      dayNames: Value(dayNames),
      syncStatus: Value(syncStatus),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
