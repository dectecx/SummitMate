import 'package:drift/drift.dart';
import 'converters/gear_set_visibility_converter.dart';

class GearSetCacheTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  RealColumn get totalWeight => real().withDefault(const Constant(0.0))();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  TextColumn get visibility => text().map(const GearSetVisibilityConverter())();
  DateTimeColumn get uploadedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  /// 用於存儲完整 GearSet 的 JSON (包含 items 和 meals 如果有的話)
  TextColumn get rawJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
