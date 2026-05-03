import 'package:drift/drift.dart';

/// 日誌表
class LogsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get level => integer()(); // LogLevel index
  TextColumn get message => text()();
  TextColumn get source => text().nullable()();
}
