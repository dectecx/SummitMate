import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/presentation/cubits/sync/sync_state.dart';

class MockSyncService extends Mock implements ISyncService {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockAuthService extends Mock implements IAuthService {}

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  late SyncCubit syncCubit;
  late MockSyncService mockSyncService;
  late MockConnectivityService mockConnectivityService;
  late MockItineraryRepository mockItineraryRepository;
  late MockAuthService mockAuthService;
  late MockTripRepository mockTripRepository;

  setUp(() {
    mockSyncService = MockSyncService();
    mockConnectivityService = MockConnectivityService();
    mockItineraryRepository = MockItineraryRepository();
    mockAuthService = MockAuthService();
    mockTripRepository = MockTripRepository();

    // Default behaviors
    when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => Stream.fromIterable([true]));
    when(() => mockSyncService.watchPendingSyncCount()).thenAnswer((_) => Stream.fromIterable([0]));
    when(() => mockSyncService.lastItinerarySync).thenReturn(null);
    when(() => mockConnectivityService.isOffline).thenReturn(false);

    syncCubit = SyncCubit(
      mockSyncService,
      mockConnectivityService,
      mockItineraryRepository,
      mockAuthService,
      mockTripRepository,
    );
  });

  tearDown(() {
    syncCubit.close();
  });

  group('SyncCubit', () {
    test('initial state is SyncInitial', () {
      expect(syncCubit.state, isA<SyncInitial>());
    });

    blocTest<SyncCubit, SyncState>(
      'syncAll emits [SyncInProgress, SyncSuccess] on success',
      build: () {
        when(
          () => mockSyncService.syncAll(isAuto: any(named: 'isAuto')),
        ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime(2024)));
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(force: true),
      expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
    );

    blocTest<SyncCubit, SyncState>(
      'syncAll emits [SyncFailure] when offline',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(true);
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(),
      expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'error message', contains('離線'))],
    );

    blocTest<SyncCubit, SyncState>(
      'syncAll emits [SyncInProgress, SyncFailure] on service failure',
      build: () {
        when(
          () => mockSyncService.syncAll(isAuto: any(named: 'isAuto')),
        ).thenAnswer((_) async => SyncResult.failure('Network Error'));
        return syncCubit;
      },
      act: (cubit) => cubit.syncAll(force: true),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncFailure>().having((s) => s.errorMessage, 'error message', 'Network Error'),
      ],
    );
  });
}
