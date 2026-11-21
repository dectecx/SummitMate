import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/sync_engine.dart';

class MockSyncAdapter extends Mock implements ISyncAdapter {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockSettings extends Mock implements Settings {}

void main() {
  late SyncEngine engine;
  late MockSyncAdapter mockAdapter;
  late MockTripRepository mockTripRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;
  late MockAppDatabase mockDb;
  late MockTripRemoteDataSource mockTripRemote;
  late MockSettings mockSettings;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockAdapter = MockSyncAdapter();
    mockTripRepo = MockTripRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();
    mockDb = MockAppDatabase();
    mockTripRemote = MockTripRemoteDataSource();
    mockSettings = MockSettings();

    when(() => mockAdapter.tableName).thenReturn('mock_table');
    when(() => mockAdapter.tracksSyncStatus).thenReturn(true);
    when(() => mockSettingsRepo.watchSettings()).thenAnswer((_) => const Stream.empty());
    when(() => mockSettings.autoSyncIntervalMinutes).thenReturn(15);
    when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => mockSettings);
    when(() => mockAuthService.currentUserId).thenReturn('user1');

    engine = SyncEngine(
      adapters: [mockAdapter],
      settingsRepo: mockSettingsRepo,
      connectivity: mockConnectivity,
      authService: mockAuthService,
      db: mockDb,
      tripRepo: mockTripRepo,
      tripRemoteDataSource: mockTripRemote,
    );
  });

  group('SyncEngine - runSyncCycle', () {
    test('Given connectivity is offline, When calling runSyncCycle, Then it should return failure', () async {
      when(() => mockConnectivity.isOffline).thenReturn(true);

      final result = await engine.runSyncCycle();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('離線模式'));
    });

    test('Given user is guest, When calling runSyncCycle, Then it should bypass and return failure', () async {
      when(() => mockAuthService.currentUserId).thenReturn('guest');

      final result = await engine.runSyncCycle();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('訪客或未登入狀態'));
    });

    test(
      'Given runSyncCycle, When triggered, Then it should drive every registered adapter and persist sync time',
      () async {
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockAuthService.currentUserId).thenReturn('user1');

        when(() => mockAdapter.pushPending()).thenAnswer((_) async => const SyncPushResult());
        when(() => mockAdapter.pullRemote()).thenAnswer((_) async => const SyncMergeResult());
        when(() => mockSettingsRepo.updateLastSyncTime(any())).thenAnswer((_) async {});

        final result = await engine.runSyncCycle();

        expect(result.isSuccess, isTrue);
        verify(() => mockAdapter.pushPending()).called(1);
        verify(() => mockAdapter.pullRemote()).called(1);
        verify(() => mockSettingsRepo.updateLastSyncTime(any())).called(1);
      },
    );

    test(
      'Given an adapter reports errors, When running cycle, Then result is not successful and time is not persisted',
      () async {
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockAuthService.currentUserId).thenReturn('user1');

        when(() => mockAdapter.pushPending()).thenAnswer((_) async => const SyncPushResult(errors: ['boom']));
        when(() => mockAdapter.pullRemote()).thenAnswer((_) async => const SyncMergeResult());

        final result = await engine.runSyncCycle();

        expect(result.isSuccess, isFalse);
        expect(result.errors, contains('boom'));
        verifyNever(() => mockSettingsRepo.updateLastSyncTime(any()));
      },
    );
  });

  group('SyncEngine - syncTrip', () {
    const tripId = 'trip-abc';

    test('Given offline, When calling syncTrip, Then returns failure', () async {
      when(() => mockConnectivity.isOffline).thenReturn(true);

      final result = await engine.syncTrip(tripId, SyncDirection.upload);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('離線模式'));
    });

    test('Given guest user, When calling syncTrip, Then returns failure', () async {
      when(() => mockAuthService.currentUserId).thenReturn('guest');

      final result = await engine.syncTrip(tripId, SyncDirection.upload);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('訪客或未登入狀態'));
    });

    test('Given upload direction, When calling syncTrip, Then calls pushPendingForTrip on adapter', () async {
      when(() => mockConnectivity.isOffline).thenReturn(false);
      when(() => mockAdapter.pushPendingForTrip(any())).thenAnswer((_) async => const SyncPushResult());

      final result = await engine.syncTrip(tripId, SyncDirection.upload);

      expect(result.isSuccess, isTrue);
      verify(() => mockAdapter.pushPendingForTrip(tripId)).called(1);
      verifyNever(() => mockAdapter.pullRemoteForTrip(any()));
    });

    test('Given download direction, When calling syncTrip, Then calls pullRemoteForTrip on adapter', () async {
      when(() => mockConnectivity.isOffline).thenReturn(false);
      when(() => mockAdapter.pullRemoteForTrip(any())).thenAnswer((_) async => const SyncMergeResult());

      final result = await engine.syncTrip(tripId, SyncDirection.download);

      expect(result.isSuccess, isTrue);
      verify(() => mockAdapter.pullRemoteForTrip(tripId)).called(1);
      verifyNever(() => mockAdapter.pushPendingForTrip(any()));
    });

    test('Given adapter push errors, When calling syncTrip upload, Then result is not successful', () async {
      when(() => mockConnectivity.isOffline).thenReturn(false);
      when(
        () => mockAdapter.pushPendingForTrip(any()),
      ).thenAnswer((_) async => const SyncPushResult(errors: ['push error']));

      final result = await engine.syncTrip(tripId, SyncDirection.upload);

      expect(result.isSuccess, isFalse);
      expect(result.errors, contains('push error'));
    });
  });
}
