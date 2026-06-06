import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/presentation/cubits/sync/sync_state.dart';

// Mocks
class MockSyncEngine extends Mock implements ISyncEngine {}

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late SyncCubit cubit;
  late MockSyncEngine mockSyncEngine;
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockSyncEngine = MockSyncEngine();
    mockConnectivityService = MockConnectivityService();

    when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    when(() => mockSyncEngine.watchPendingSyncCount()).thenAnswer((_) => const Stream.empty());
    when(() => mockSyncEngine.getLastSyncTime()).thenAnswer((_) async => null);
  });

  tearDown(() {
    cubit.close();
  });

  group('SyncCubit', () {
    test('Given SyncCubit, When executing, Then initial state is SyncInitial', () {
      when(() => mockConnectivityService.isOffline).thenReturn(false);

      cubit = SyncCubit(mockSyncEngine, mockConnectivityService);

      expect(cubit.state, isA<SyncInitial>());
    });

    group('syncAll', () {
      blocTest<SyncCubit, SyncState>(
        'emits SyncFailure when offline',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(true);
        },
        build: () => SyncCubit(mockSyncEngine, mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] on successful sync',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(
            () => mockSyncEngine.runSyncCycle(force: any(named: 'force')),
          ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime.now()));
        },
        build: () => SyncCubit(mockSyncEngine, mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );
    });
  });
}
