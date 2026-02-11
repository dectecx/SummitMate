import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/presentation/cubits/sync/sync_state.dart';

// Mocks
class MockSyncService extends Mock implements ISyncService {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class FakeSyncResult extends Fake implements SyncResult {}

void main() {
  late SyncCubit cubit;
  late MockSyncService mockSyncService;
  late MockConnectivityService mockConnectivityService;

  setUpAll(() {
    registerFallbackValue(FakeSyncResult());
  });

  setUp(() {
    mockSyncService = MockSyncService();
    mockConnectivityService = MockConnectivityService();
  });

  tearDown(() {
    cubit.close();
  });

  group('SyncCubit', () {
    test('initial state is SyncInitial with lastSyncTime', () {
      final now = DateTime.now();
      when(() => mockSyncService.lastItinerarySync).thenReturn(now);
      when(() => mockConnectivityService.isOffline).thenReturn(false);

      cubit = SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService);

      expect(cubit.state, isA<SyncInitial>().having((s) => s.lastSyncTime, 'lastSyncTime', now));
    });

    group('syncAll', () {
      blocTest<SyncCubit, SyncState>(
        'emits SyncFailure when offline',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(true);
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] on successful sync',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          // Match explicit calls. Default syncAll({force=false}) -> isAuto: true
          when(
            () => mockSyncService.syncAll(isAuto: true),
          ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime.now()));
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] (skipped) when throttled',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(
            () => mockSyncService.syncAll(isAuto: true),
          ).thenAnswer((_) async => SyncResult.skipped(reason: 'Throttled'));
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>().having((s) => s.message, 'message', contains('已略過'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncFailure] on sync error',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(() => mockSyncService.syncAll(isAuto: true)).thenAnswer((_) async => SyncResult.failure('API Error'));
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [
          isA<SyncInProgress>(),
          isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', 'API Error'),
        ],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncFailure] on exception',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(() => mockSyncService.syncAll(isAuto: true)).thenThrow(Exception('Unexpected'));
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncFailure>()],
      );
    });

    group('uploadItinerary', () {
      blocTest<SyncCubit, SyncState>(
        'emits SyncFailure when offline',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(true);
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] on success',
        setUp: () {
          when(() => mockSyncService.lastItinerarySync).thenReturn(null);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(
            () => mockSyncService.uploadItinerary(),
          ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime.now()));
        },
        build: () => SyncCubit(syncService: mockSyncService, connectivityService: mockConnectivityService),
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );
    });
  });
}
