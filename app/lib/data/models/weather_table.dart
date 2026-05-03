import 'package:drift/drift.dart';

/// 天氣資料快取表
class WeatherDataTable extends Table {
  TextColumn get id => text()(); // 通常是 "location_township"
  TextColumn get data => text()(); // JSON string
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
