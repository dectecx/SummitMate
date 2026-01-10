import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/presentation/cubits/sync/sync_state.dart';

class MockSyncService extends Mock implements ISyncService {}
class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  group('SyncCubit', () {
    late MockSyncService mockSyncService;
    late MockConnectivityService mockConnectivityService;
    late SyncCubit syncCubit;

    setUp(() {
      mockSyncService = MockSyncService();
      mockConnectivityService = MockConnectivityService();
      
      // Default behavior for init
      when(() => mockSyncService.lastItinerarySync).thenReturn(null);

      syncCubit = SyncCubit(
        syncService: mockSyncService,
        connectivityService: mockConnectivityService,
      );
    });

    tearDown(() {
      syncCubit.close();
    });

    test('initial state is SyncInitial', () {
      expect(syncCubit.state, isA<SyncInitial>());
    });

    blocTest<SyncCubit, SyncState>(
      'emits [SyncFailure] when offline',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(true);
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(),
      expect: () => [
        isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式')),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'emits [SyncInProgress, SyncSuccess] when sync is successful',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        final result = SyncResult(isSuccess: true, itinerarySynced: true, messagesSynced: true, syncedAt: DateTime.now());
        when(() => mockSyncService.syncAll(isAuto: any(named: 'isAuto'))).thenAnswer((_) async => result);
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(force: true),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncSuccess>().having((s) => s.message, 'message', '同步成功'),
      ],
      verify: (_) {
        verify(() => mockSyncService.syncAll(isAuto: false)).called(1);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'emits [SyncInProgress, SyncFailure] when sync fails',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        final result = SyncResult.failure('Network Error');
        when(() => mockSyncService.syncAll(isAuto: any(named: 'isAuto'))).thenAnswer((_) async => result);
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', 'Network Error'),
      ],
    );
    
    blocTest<SyncCubit, SyncState>(
      'emits [SyncInProgress, SyncSuccess] even if nothing synced (but operation success)',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        // isSuccess: true but maybe nothing synced
        final result = SyncResult.success(itinerarySynced: false, messagesSynced: false);
        when(() => mockSyncService.syncAll(isAuto: any(named: 'isAuto'))).thenAnswer((_) async => result);
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncSuccess>().having((s) => s.message, 'message', '同步成功'),
      ],
    );
  });
}
