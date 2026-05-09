import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
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

  late StreamController<bool> connectivityController;
  late StreamController<int> pendingCountController;

  setUp(() {
    mockSyncService = MockSyncService();
    mockConnectivityService = MockConnectivityService();
    mockItineraryRepository = MockItineraryRepository();
    mockAuthService = MockAuthService();
    mockTripRepository = MockTripRepository();

    connectivityController = StreamController<bool>.broadcast();
    pendingCountController = StreamController<int>.broadcast();

    // Default behaviors
    when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => connectivityController.stream);
    when(() => mockSyncService.watchPendingSyncCount()).thenAnswer((_) => pendingCountController.stream);
    when(() => mockSyncService.lastItinerarySync).thenReturn(null);
    when(() => mockConnectivityService.isOffline).thenReturn(false);
    when(() => mockAuthService.currentUserId).thenReturn('test-user');

    syncCubit = SyncCubit(
      mockSyncService,
      mockConnectivityService,
      mockItineraryRepository,
      mockAuthService,
      mockTripRepository,
    );
  });

  tearDown(() {
    connectivityController.close();
    pendingCountController.close();
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
      'connectivity change updates state isOnline property',
      build: () => syncCubit,
      act: (cubit) => connectivityController.add(false),
      expect: () => [isA<SyncInitial>().having((s) => s.isOnline, 'isOffline', false)],
    );

    blocTest<SyncCubit, SyncState>(
      'pendingCount update from service updates state',
      build: () => syncCubit,
      act: (cubit) => pendingCountController.add(5),
      expect: () => [isA<SyncInitial>().having((s) => s.pendingCount, 'count', 5)],
    );

    blocTest<SyncCubit, SyncState>(
      'automatic sync when connectivity restored after offline failure',
      build: () {
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        when(
          () => mockSyncService.syncAll(isAuto: any(named: 'isAuto')),
        ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime(2024)));
        return syncCubit;
      },
      seed: () => const SyncFailure(errorMessage: '目前處於離線模式，無法同步', isOnline: false),
      act: (cubit) => connectivityController.add(true),
      expect: () => [
        isA<SyncFailure>().having((s) => s.isOnline, 'isOnline', true),
        isA<SyncInProgress>(),
        isA<SyncSuccess>(),
      ],
    );

    group('uploadItinerary', () {
      final mockTrip = Trip(
        id: 'trip-1',
        userId: 'test-user',
        name: 'Test Trip',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        updatedAt: DateTime.now(),
        updatedBy: 'test-user',
      );

      blocTest<SyncCubit, SyncState>(
        'uploadItinerary emits [SyncInProgress, SyncSuccess] on success',
        build: () {
          when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(mockTrip));
          when(() => mockItineraryRepository.sync(any())).thenAnswer((_) async => Success(null));
          return syncCubit;
        },
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );

      blocTest<SyncCubit, SyncState>(
        'uploadItinerary emits [SyncFailure] if no active trip',
        build: () {
          when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));
          return syncCubit;
        },
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'error message', '找不到活動行程')],
      );
    });
  });
}
