import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';
import 'package:summitmate/presentation/cubits/sync/sync_state.dart';

// Mocks
class MockSyncService extends Mock implements ISyncService {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

class FakeSyncResult extends Fake implements SyncResult {}

class FakeTrip extends Fake implements Trip {}

void main() {
  late SyncCubit cubit;
  late MockSyncService mockSyncService;
  late MockConnectivityService mockConnectivityService;
  late MockItineraryRepository mockItineraryRepo;
  late MockTripRepository mockTripRepo;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakeSyncResult());
    registerFallbackValue(FakeTrip());
  });

  setUp(() {
    mockSyncService = MockSyncService();
    mockConnectivityService = MockConnectivityService();
    mockItineraryRepo = MockItineraryRepository();
    mockTripRepo = MockTripRepository();
    mockAuthService = MockAuthService();

    when(() => mockSyncService.lastItinerarySync).thenReturn(null);
    when(() => mockAuthService.currentUserId).thenReturn('u1');
  });

  tearDown(() {
    cubit.close();
  });

  group('SyncCubit', () {
    test('initial state is SyncInitial with lastSyncTime', () {
      final now = DateTime.now();
      when(() => mockSyncService.lastItinerarySync).thenReturn(now);
      when(() => mockConnectivityService.isOffline).thenReturn(false);

      cubit = SyncCubit(
        syncService: mockSyncService,
        connectivityService: mockConnectivityService,
        itineraryRepository: mockItineraryRepo,
        authService: mockAuthService,
        tripRepository: mockTripRepo,
      );

      expect(cubit.state, isA<SyncInitial>().having((s) => s.lastSyncTime, 'lastSyncTime', now));
    });

    group('syncAll', () {
      blocTest<SyncCubit, SyncState>(
        'emits SyncFailure when offline',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(true);
        },
        build: () => SyncCubit(
          syncService: mockSyncService,
          connectivityService: mockConnectivityService,
          itineraryRepository: mockItineraryRepo,
          authService: mockAuthService,
          tripRepository: mockTripRepo,
        ),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] on successful sync',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(
            () => mockSyncService.syncAll(isAuto: true),
          ).thenAnswer((_) async => SyncResult.success(syncedAt: DateTime.now()));
        },
        build: () => SyncCubit(
          syncService: mockSyncService,
          connectivityService: mockConnectivityService,
          itineraryRepository: mockItineraryRepo,
          authService: mockAuthService,
          tripRepository: mockTripRepo,
        ),
        act: (cubit) => cubit.syncAll(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );
    });

    group('uploadItinerary', () {
      blocTest<SyncCubit, SyncState>(
        'emits SyncFailure when offline',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(true);
        },
        build: () => SyncCubit(
          syncService: mockSyncService,
          connectivityService: mockConnectivityService,
          itineraryRepository: mockItineraryRepo,
          authService: mockAuthService,
          tripRepository: mockTripRepo,
        ),
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncFailure>().having((s) => s.errorMessage, 'errorMessage', contains('離線模式'))],
      );

      blocTest<SyncCubit, SyncState>(
        'emits [SyncInProgress, SyncSuccess] on success',
        setUp: () {
          when(() => mockConnectivityService.isOffline).thenReturn(false);
          when(() => mockTripRepo.getActiveTrip(any())).thenAnswer(
            (_) async => Success(
              Trip(
                id: 't1',
                userId: 'u1',
                name: 'T',
                startDate: DateTime.now(),
                isActive: true,
                createdAt: DateTime.now(),
                createdBy: 'u1',
                updatedAt: DateTime.now(),
                updatedBy: 'u1',
              ),
            ),
          );
          when(() => mockItineraryRepo.sync('t1')).thenAnswer((_) async => const Success(null));
        },
        build: () => SyncCubit(
          syncService: mockSyncService,
          connectivityService: mockConnectivityService,
          itineraryRepository: mockItineraryRepo,
          authService: mockAuthService,
          tripRepository: mockTripRepo,
        ),
        act: (cubit) => cubit.uploadItinerary(),
        expect: () => [isA<SyncInProgress>(), isA<SyncSuccess>()],
      );
    });
  });
}
