import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/sync_engine.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockSettings extends Mock implements Settings {}

/// 只提供資料表資訊的 adapter，用來驗證引擎對真實資料庫產生的 SQL。
class FakeSyncAdapter implements ISyncAdapter {
  FakeSyncAdapter(this.tableName, {required this.tracksSyncStatus});

  @override
  final String tableName;

  @override
  final bool tracksSyncStatus;

  @override
  Future<SyncPushResult> pushPending() async => const SyncPushResult();

  @override
  Future<SyncPushResult> pushPendingForTrip(String tripId) async => const SyncPushResult();

  @override
  Future<SyncMergeResult> pullRemote() async => const SyncMergeResult();

  @override
  Future<SyncMergeResult> pullRemoteForTrip(String tripId) async => const SyncMergeResult();
}

void main() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final settingsRepo = MockSettingsRepository();
    final settings = MockSettings();
    when(() => settingsRepo.watchSettings()).thenAnswer((_) => const Stream.empty());
    when(() => settings.autoSyncIntervalMinutes).thenReturn(0);
    when(() => settingsRepo.getSettings()).thenAnswer((_) async => settings);

    engine = SyncEngine(
      // 對應 SyncModule 的真實組合：糧食天數資料表沒有 sync_status 欄位
      adapters: [
        FakeSyncAdapter('trips_table', tracksSyncStatus: true),
        FakeSyncAdapter('itinerary_items_table', tracksSyncStatus: true),
        FakeSyncAdapter('gear_items_table', tracksSyncStatus: true),
        FakeSyncAdapter('favorites_table', tracksSyncStatus: true),
        FakeSyncAdapter('meal_plan_days_table', tracksSyncStatus: false),
      ],
      settingsRepo: settingsRepo,
      connectivity: MockConnectivityService(),
      authService: MockAuthService(),
      db: db,
      tripRepo: MockTripRepository(),
      tripRemoteDataSource: MockTripRemoteDataSource(),
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  group('SyncEngine - watchPendingSyncCount (real database)', () {
    test(
      'Given a pull-only table without sync_status, When watching pending count, Then it queries without errors',
      () async {
        final count = await engine.watchPendingSyncCount().first;

        expect(count, 0);
      },
    );

    test('Given a trip that is not synced, When watching pending count, Then it is counted', () async {
      await db.customInsert(
        'INSERT INTO trips_table (id, user_id, name, start_date, is_active, created_at, created_by, updated_at, updated_by, sync_status) '
        "VALUES ('t1', 'u1', 'Trip', 1775563200, 0, 1775563200, 'u1', 1775563200, 'u1', 'error')",
        updates: {db.tripsTable},
      );

      final count = await engine.watchPendingSyncCount().first;

      expect(count, 1);
    });
  });

  group('SyncEngine - watchSyncStatus', () {
    test(
      'Given a table without sync_status, When watching its status, Then it reports synced instead of failing',
      () async {
        final status = await engine.watchSyncStatus('meal_plan_days_table').first;

        expect(status, SyncStatus.synced);
      },
    );

    test('Given a tracked table with no pending rows, When watching its status, Then it reports synced', () async {
      final status = await engine.watchSyncStatus('trips_table').first;

      expect(status, SyncStatus.synced);
    });
  });
}
