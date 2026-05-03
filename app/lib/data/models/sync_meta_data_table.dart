import 'package:drift/drift.dart';

/// 用於儲存各項資料類型的同步狀態 (如最後同步時間)
class SyncMetaDataTable extends Table {
  /// 資料類型識別碼 (如 'messages', 'polls', 'itinerary' 等)
  TextColumn get key => text()();

  /// 最後同步時間
  DateTimeColumn get lastSyncTime => dateTime().nullable()();

  /// 額外的同步資訊 (可選)
  TextColumn get extraInfo => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
