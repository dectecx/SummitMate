import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/database/database_migration_manager.dart';

// Mock PathProvider for testing
class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  late Directory tempDir;
  late String dbPath;
  late String backupPath;

  setUp(() async {
    // 建立臨時測試目錄
    tempDir = await Directory.systemTemp.createTemp('summitmate_migration_test_');
    dbPath = p.join(tempDir.path, '${AppDatabase.databaseName}.sqlite');
    backupPath = p.join(tempDir.path, '${AppDatabase.databaseName}_backup.sqlite');

    // 註冊 Mock PathProvider
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    // 清理臨時目錄
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 建立含有舊 Schema 結構的舊資料庫
  void createOldDatabaseWithSchema1(String path) {
    final db = sqlite.sqlite3.open(path);
    // 建立 trips_table 資料表 (舊結構只有 id, name, old_column)
    db.execute('''
      CREATE TABLE trips_table (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        old_column TEXT,
        created_at INTEGER NOT NULL,
        created_by TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        updated_by TEXT NOT NULL
      )
    ''');

    // 寫入一筆測試資料 (使用 1775563200 代表 2026-06-06T12:00:00Z 的 Unix 時間戳)
    db.execute(
      '''
      INSERT INTO trips_table (id, user_id, name, start_date, is_active, old_column, created_at, created_by, updated_at, updated_by)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      ['trip_123', 'user_abc', '舊行程名稱', 1775563200, 1, '這是舊版專有欄位資料', 1775563200, 'user_abc', 1775563200, 'user_abc'],
    );
    db.dispose();
  }

  group('DatabaseMigrationManager 遷移整合測試', () {
    test('Given DatabaseMigrationManager 遷移整合測試, When 執行測試, Then 狀況三：全新安裝 - 資料庫不存在時，直接設定版號並不執行遷移', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = DatabaseMigrationManager(prefs);

      double lastProgress = 0.0;
      String lastMessage = '';

      await manager.checkAndMigrate(
        currentVersion: 2,
        onProgress: (p, msg) {
          lastProgress = p;
          lastMessage = msg;
        },
      );

      expect(lastProgress, 1.0);
      expect(lastMessage, '初始化完成');
      expect(prefs.getInt('db_schema_version'), 2);
      expect(prefs.getString('db_migration_status'), 'idle');
      expect(File(dbPath).existsSync(), isFalse); // 全新安裝只寫入版號，實際連線建立檔案
    });

    test('Given DatabaseMigrationManager 遷移整合測試, When 執行測試, Then 狀況四：常規更新遷移 - 舊資料庫成功備份、重建、欄位交集對應與遷移', () async {
      // 1. 建立舊資料庫
      createOldDatabaseWithSchema1(dbPath);
      expect(File(dbPath).existsSync(), isTrue);

      // 2. 設定 SharedPreferences 起始狀態 (版號 1)
      SharedPreferences.setMockInitialValues({'db_schema_version': 1, 'db_migration_status': 'idle'});
      final prefs = await SharedPreferences.getInstance();
      final manager = DatabaseMigrationManager(prefs);

      // 3. 執行升級遷移 (目標版號 2)
      final progressSteps = <double>[];
      await manager.checkAndMigrate(
        currentVersion: 2,
        onProgress: (p, msg) {
          progressSteps.add(p);
        },
      );

      // 驗證進度正確性
      expect(progressSteps.last, 1.0);
      expect(prefs.getInt('db_schema_version'), 2);
      expect(prefs.getString('db_migration_status'), 'completed');

      // 驗證備份檔案已被刪除
      expect(File(backupPath).existsSync(), isFalse);

      // 4. 開啟新資料庫，驗證資料是否遷移成功，且新舊欄位對應無誤
      final newDb = AppDatabase();
      final allTrips = await newDb.select(newDb.tripsTable).get();
      expect(allTrips.length, 1);

      final migratedTrip = allTrips.first;
      expect(migratedTrip.id, 'trip_123');
      expect(migratedTrip.name, '舊行程名稱');
      expect(migratedTrip.userId, 'user_abc');

      // 驗證新欄位 (如 description，在舊資料表沒有，所以應為 null)
      expect(migratedTrip.description, isNull);

      await newDb.close();
    });

    test(
      'Given DatabaseMigrationManager 遷移整合測試, When 執行測試, Then 狀況一：中斷自我修復 - 偵測到遷移狀態為 started，自動清理半殘主庫並從備份重新移轉',
      () async {
        // 1. 建立舊備份資料庫檔案
        createOldDatabaseWithSchema1(backupPath);
        expect(File(backupPath).existsSync(), isTrue);

        // 2. 建立一個損毀/半殘的主資料庫檔案
        final brokenDbFile = File(dbPath);
        await brokenDbFile.writeAsString('corrupted data half written');

        // 3. 設定 SharedPreferences 起始狀態為 started (代表先前中斷)
        SharedPreferences.setMockInitialValues({
          'db_schema_version': 1,
          'db_migration_status': 'started',
          'db_backup_path': backupPath,
        });
        final prefs = await SharedPreferences.getInstance();
        final manager = DatabaseMigrationManager(prefs);

        // 4. 重新執行檢查
        await manager.checkAndMigrate(currentVersion: 2);

        // 驗證遷移重啟成功
        expect(prefs.getInt('db_schema_version'), 2);
        expect(prefs.getString('db_migration_status'), 'completed');
        expect(File(backupPath).existsSync(), isFalse);

        // 5. 驗證資料是否最終正確恢復
        final newDb = AppDatabase();
        final allTrips = await newDb.select(newDb.tripsTable).get();
        expect(allTrips.length, 1);
        expect(allTrips.first.id, 'trip_123');
        expect(allTrips.first.name, '舊行程名稱');
        await newDb.close();
      },
    );
  });
}
