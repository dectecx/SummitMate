import 'package:drift/drift.dart';


class GearSetCacheTable extends Table {
  TextColumn get id => text()();

  /// 用於存儲完整 GearSet 的 JSON (包含 items 和 meals 如果有的話)
  TextColumn get rawJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}
