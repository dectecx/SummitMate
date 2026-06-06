import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sqlite3_helper.dart';
import 'package:drift/drift.dart';
import 'app_database.dart';

typedef MigrationProgressCallback = void Function(double progress, String message);

/// DatabaseMigrationManager 負責處理 Drift SQLite 資料庫的升級與資料安全轉移。
/// 採用「備份 -> 重建新庫 -> 交集欄位動態拷貝 -> 清除備份」的策略，並提供中斷重試的容錯機制。
class DatabaseMigrationManager {
  final SharedPreferences prefs;

  DatabaseMigrationManager(this.prefs);

  static const String _versionKey = 'db_schema_version';
  static const String _statusKey = 'db_migration_status';
  static const String _backupPathKey = 'db_backup_path';

  static const String statusIdle = 'idle';
  static const String statusStarted = 'started';
  static const String statusCompleted = 'completed';

  /// 檢查版號並執行資料庫遷移。如果需要遷移，將會回報進度與狀態文字。
  Future<void> checkAndMigrate({required int currentVersion, MigrationProgressCallback? onProgress}) async {
    if (kIsWeb) {
      // 網頁版不支援檔案操作，直接更新版號完成
      await prefs.setInt(_versionKey, currentVersion);
      onProgress?.call(1.0, '初始化完成');
      return;
    }

    final int oldVersion = prefs.getInt(_versionKey) ?? 0;
    final String migrationStatus = prefs.getString(_statusKey) ?? statusIdle;
    final String? savedBackupPath = prefs.getString(_backupPathKey);

    final supportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(supportDir.path, 'summitmate_db.sqlite');
    final backupPath = p.join(supportDir.path, 'summitmate_db_backup.sqlite');

    final dbFile = File(dbPath);
    final backupFile = File(backupPath);

    // ==========================================
    // 狀況一：偵測到上一次遷移發生中斷 (Crash 或異常中斷)
    // ==========================================
    if (migrationStatus == statusStarted || (await backupFile.exists() && migrationStatus != statusCompleted)) {
      onProgress?.call(0.1, '偵測到未完成的遷移，正在修復並重新開始...');

      // 清空主資料庫檔案（確保重新開始時是乾淨的新庫，防殘留）
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      final sourceBackupPath = savedBackupPath ?? backupPath;
      await _executeHandover(
        backupPath: sourceBackupPath,
        dbPath: dbPath,
        oldVersion: oldVersion == 0 ? 1 : oldVersion,
        newVersion: currentVersion,
        onProgress: onProgress,
      );
      return;
    }

    // ==========================================
    // 狀況二：正常啟動，版號一致，不需要升級
    // ==========================================
    if (oldVersion >= currentVersion) {
      onProgress?.call(1.0, '初始化完成');
      return;
    }

    // ==========================================
    // 狀況三：全新安裝 (無資料庫檔案)
    // ==========================================
    if (!await dbFile.exists()) {
      onProgress?.call(0.5, '建立本地快取資料庫...');
      await prefs.setInt(_versionKey, currentVersion);
      await prefs.setString(_statusKey, statusIdle);
      onProgress?.call(1.0, '初始化完成');
      return;
    }

    // ==========================================
    // 狀況四：需要執行升級遷移！
    // ==========================================
    onProgress?.call(0.15, '準備更新本地資料庫...');

    // 1. 備份舊的資料庫檔案
    onProgress?.call(0.25, '正在備份現有快取資料...');
    await dbFile.copy(backupPath);

    // 2. 標記狀態為 started
    await prefs.setString(_statusKey, statusStarted);
    await prefs.setString(_backupPathKey, backupPath);

    // 3. 刪除舊的主庫，以便待會 Drift 開啟時以最新 Schema 執行 onCreate
    onProgress?.call(0.35, '重建資料表結構...');
    await dbFile.delete();

    // 4. 執行資料移轉
    await _executeHandover(
      backupPath: backupPath,
      dbPath: dbPath,
      oldVersion: oldVersion == 0 ? 1 : oldVersion,
      newVersion: currentVersion,
      onProgress: onProgress,
    );
  }

  /// 執行資料庫交集欄位對應與移轉
  Future<void> _executeHandover({
    required String backupPath,
    required String dbPath,
    required int oldVersion,
    required int newVersion,
    MigrationProgressCallback? onProgress,
  }) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      await prefs.setString(_statusKey, statusIdle);
      throw Exception('備份資料檔案不存在，無法進行遷移。');
    }

    onProgress?.call(0.4, '正在轉換資料庫結構...');

    // 1. 實例化新資料庫（此時會觸發 onCreate 建立全新且乾淨的所有表）
    final newDb = AppDatabase();

    SqliteDbWrapper? oldDb;
    try {
      // 2. 使用 sqlite3 直接開啟舊的唯讀備份資料庫
      oldDb = openSqliteDb(backupPath);

      final tables = newDb.allTables.toList();
      final totalTables = tables.length;

      // 3. 遍歷每一個表，進行動態欄位比對與資料拷貝
      for (int i = 0; i < totalTables; i++) {
        final table = tables[i];
        final tableName = table.actualTableName;

        // 計算對應的進度 (0.4 到 0.8)
        final double progressFactor = 0.4 + (0.4 * (i / totalTables));
        onProgress?.call(progressFactor, '正在恢復資料表: $tableName ...');

        // 檢查該資料表是否存在於舊庫中
        final checkTable = oldDb.select("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [tableName]);
        if (checkTable.isEmpty) {
          continue; // 舊庫無此表，略過
        }

        // 獲取新表所有欄位名稱
        final newColumns = table.$columns.map((c) => c.name).toSet();

        // 獲取舊表的 pragma 資訊，解析欄位
        final pragmaInfo = oldDb.select("PRAGMA table_info($tableName)");
        final oldColumns = pragmaInfo.map((row) => row['name'] as String).toSet();

        // 計算新舊欄位的交集
        final commonColumns = newColumns.intersection(oldColumns).toList();
        if (commonColumns.isEmpty) {
          continue; // 沒有交集欄位，略過
        }

        // 讀取舊表所有資料
        final oldRows = oldDb.select("SELECT * FROM $tableName");
        if (oldRows.isEmpty) {
          continue; // 舊表無資料，略過
        }

        // 動態生成 INSERT 語法 (對欄位加上雙引號保護，避免 SQLite 保留字衝突)
        final escapedColumns = commonColumns.map((col) => '"$col"').toList();
        final placeholders = commonColumns.map((_) => '?').join(', ');
        final insertSql = "INSERT INTO $tableName (${escapedColumns.join(', ')}) VALUES ($placeholders)";

        // 在 Transaction 中批次寫入新庫
        await newDb.transaction(() async {
          for (final row in oldRows) {
            final values = commonColumns.map((col) => row[col]).toList();
            await newDb.customInsert(
              insertSql,
              variables: values.map<Variable<Object>>((v) {
                if (v == null) return const Variable<Object>(null);
                if (v is int) return Variable.withInt(v);
                if (v is double) return Variable.withReal(v);
                if (v is String) return Variable.withString(v);
                if (v is Uint8List) return Variable.withBlob(v);
                return Variable<Object>(v as Object);
              }).toList(),
            );
          }
        });
      }

      onProgress?.call(0.85, '完成資料導入，正在進行安全檢查與清理...');

      // 4. 關閉資料庫連線，釋放檔案鎖
      oldDb.dispose();
      oldDb = null;
      await newDb.close();

      // 5. 刪除備份檔
      await backupFile.delete();

      // 6. 標記狀態與新版號
      await prefs.setInt(_versionKey, newVersion);
      await prefs.setString(_statusKey, statusCompleted);
      await prefs.remove(_backupPathKey);

      onProgress?.call(1.0, '資料庫優化與升級完成！');
    } catch (e) {
      // 確保資源釋放
      try {
        oldDb?.dispose();
      } catch (_) {}
      try {
        await newDb.close();
      } catch (_) {}

      onProgress?.call(0.9, '遷移發生錯誤: $e');
      rethrow;
    }
  }
}
