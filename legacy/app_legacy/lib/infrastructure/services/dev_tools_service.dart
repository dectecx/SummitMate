import 'package:injectable/injectable.dart';

import '../../domain/domain.dart';
import '../database/app_database.dart';

/// [IDevToolsService] 實作
///
/// 將 Debug 工具的本地資料操作集中於 infrastructure 層，封裝 [AppDatabase] 細節。
@LazySingleton(as: IDevToolsService)
class DevToolsService implements IDevToolsService {
  final AppDatabase _db;

  DevToolsService({required AppDatabase db}) : _db = db;

  @override
  Future<void> clearSelectedData({
    bool trips = false,
    bool messages = false,
    bool gear = false,
    bool gearLibrary = false,
    bool polls = false,
    bool groupEvents = false,
    bool favorites = false,
    bool logs = false,
    bool settings = false,
    bool weather = false,
  }) {
    return _db.clearSelectedData(
      trips: trips,
      messages: messages,
      gear: gear,
      gearLibrary: gearLibrary,
      polls: polls,
      groupEvents: groupEvents,
      favorites: favorites,
      logs: logs,
      settings: settings,
      weather: weather,
    );
  }

  @override
  Future<List<String>> getTableNames() async {
    return _db.allTables.map((t) => t.actualTableName).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableData(String tableName, {int limit = 100}) async {
    // 僅允許已知資料表，避免任意字串插入查詢。
    final validTables = _db.allTables.map((t) => t.actualTableName).toSet();
    if (!validTables.contains(tableName)) {
      throw ArgumentError('Unknown table: $tableName');
    }
    final results = await _db.customSelect('SELECT * FROM $tableName LIMIT $limit').get();
    return results.map((row) => row.data).toList();
  }
}
