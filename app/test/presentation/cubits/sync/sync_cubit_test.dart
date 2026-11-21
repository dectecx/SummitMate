import 'dart:async';

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
            () => mockSyncEngine.runSyncCycle(),
          ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime.now()));
        },
        build: () => SyncCubit(mockSyncEngine, mockConnectivityService),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );

      group('reconnect', () {
        test(
          'Given a sync blocked while offline, When the network returns, Then it syncs once automatically',
          () async {
            final connectivity = StreamController<bool>.broadcast();
            addTearDown(connectivity.close);
            when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => connectivity.stream);
            var offline = true;
            when(() => mockConnectivityService.isOffline).thenAnswer((_) => offline);
            when(() => mockSyncEngine.runSyncCycle()).thenAnswer((_) async => SyncResult.success());
            cubit = SyncCubit(mockSyncEngine, mockConnectivityService);

            await cubit.syncAll(); // blocked: offline
            verifyNever(() => mockSyncEngine.runSyncCycle());

            offline = false;
            connectivity.add(true);
            await Future<void>.delayed(Duration.zero);
            await Future<void>.delayed(Duration.zero);

            verify(() => mockSyncEngine.runSyncCycle()).called(1);

            // 之後再次出現連線事件不應重複觸發
            connectivity.add(true);
            await Future<void>.delayed(Duration.zero);
            verifyNever(() => mockSyncEngine.runSyncCycle());
          },
        );

        test('Given no sync was blocked, When the network returns, Then nothing is triggered', () async {
          final connectivity = StreamController<bool>.broadcast();
          addTearDown(connectivity.close);
          when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => connectivity.stream);
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          cubit = SyncCubit(mockSyncEngine, mockConnectivityService);

          connectivity.add(true);
          await Future<void>.delayed(Duration.zero);

          verifyNever(() => mockSyncEngine.runSyncCycle());
        });

        test(
          'Given a failed sync caused by a server error, When the network returns, Then it does not retry by message text',
          () async {
            final connectivity = StreamController<bool>.broadcast();
            addTearDown(connectivity.close);
            when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => connectivity.stream);
            when(() => mockConnectivityService.isOffline).thenReturn(false);
            when(() => mockSyncEngine.runSyncCycle()).thenAnswer((_) async => SyncResult.failure('離線 server said so'));
            cubit = SyncCubit(mockSyncEngine, mockConnectivityService);

            await cubit.syncAll();
            clearInteractions(mockSyncEngine);
            connectivity.add(true);
            await Future<void>.delayed(Duration.zero);

            verifyNever(() => mockSyncEngine.runSyncCycle());
          },
        );
      });
    });
  });
}
