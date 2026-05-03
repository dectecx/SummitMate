import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../models/log_table.dart';
import '../../../infrastructure/tools/log_service.dart';

part 'log_dao.g.dart';

@LazySingleton()
@DriftAccessor(tables: [LogsTable])
class LogDao extends DatabaseAccessor<AppDatabase> with _$LogDaoMixin {
  LogDao(AppDatabase db) : super(db);

  Future<List<LogEntry>> getAllLogs() async {
    final rows = await (select(
      logsTable,
    )..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  Future<void> addLog(LogEntry entry) async {
    await into(logsTable).insert(
      LogsTableCompanion.insert(
        timestamp: entry.timestamp,
        level: entry.level.index,
        message: entry.message,
        source: Value(entry.source),
      ),
    );
  }

  Future<void> deleteOldLogs(int maxCount) async {
    final countQuery = countAll();
    final count = await (selectOnly(
      logsTable,
    )..addColumns([countQuery])).map((row) => row.read(countQuery)).getSingle();

    if (count != null && count > maxCount) {
      final deleteCount = count - maxCount;
      // Drift doesn't support LIMIT in DELETE directly in a simple way for all platforms,
      // so we select the IDs to delete.
      final oldIdsQuery = select(logsTable)
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)])
        ..limit(deleteCount);
      final oldIds = await oldIdsQuery.get();

      if (oldIds.isNotEmpty) {
        await (delete(logsTable)..where((t) => t.id.isIn(oldIds.map((e) => e.id)))).go();
      }
    }
  }

  Future<void> clearAll() async {
    await delete(logsTable).go();
  }

  LogEntry _mapToDomain(LogsTableData row) {
    return LogEntry(
      timestamp: row.timestamp,
      level: LogLevel.values[row.level],
      message: row.message,
      source: row.source,
    );
  }
}
