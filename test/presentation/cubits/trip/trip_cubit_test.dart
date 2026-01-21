import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';

import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/core/error/result.dart';

import 'package:summitmate/domain/interfaces/i_auth_service.dart';

import 'package:get_it/get_it.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

class MockAuthService extends Mock implements IAuthService {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockSyncService mockSyncService;
  late MockAuthService mockAuthService;
  late MockItineraryRepository mockItineraryRepository;
  late MockGearRepository mockGearRepository;

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockSyncService = MockSyncService();
    mockAuthService = MockAuthService();
    mockItineraryRepository = MockItineraryRepository();
    mockGearRepository = MockGearRepository();

    // Reset GetIt to clear previous registrations
    GetIt.I.reset();

    // Register mocks needed by TripCubit's internal DI calls (e.g., in uploadFullTrip)
    GetIt.I.registerSingleton<IItineraryRepository>(mockItineraryRepository);
    GetIt.I.registerSingleton<IGearRepository>(mockGearRepository);
    // Explicitly register others just in case code falls back to DI (though constructor injection is used for main deps)
    GetIt.I.registerSingleton<ITripRepository>(mockTripRepository);
    GetIt.I.registerSingleton<ISyncService>(mockSyncService);
    GetIt.I.registerSingleton<IAuthService>(mockAuthService);

    // Default stubs
    when(() => mockAuthService.currentUserId).thenReturn('user-1');
    when(() => mockAuthService.currentUserEmail).thenReturn('user@example.com');

    // Register fallback values if needed
    registerFallbackValue(
      Trip(
        id: 'fallback',
        userId: 'u1',
        name: 'fallback',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'u1',
        updatedAt: DateTime.now(),
        updatedBy: 'u1',
      ),
    );
  });

  group('TripCubit', () {
    final trip1 = Trip(
      id: 'trip1',
      userId: 'user-1',
      name: 'Trip 1',
      startDate: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime(2023, 1, 1),
      updatedBy: 'user-1',
      isActive: true,
    );
    final trip2 = Trip(
      id: 'trip2',
      userId: 'user-1',
      name: 'Trip 2',
      startDate: DateTime(2023, 2, 1),
      createdAt: DateTime(2023, 2, 1),
      createdBy: 'user-1',
      updatedAt: DateTime(2023, 2, 1),
      updatedBy: 'user-1',
      isActive: false,
    );

    test('initial state is TripInitial', () {
      expect(
        TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService, authService: mockAuthService).state,
        const TripInitial(),
      );
    });

    blocTest<TripCubit, TripState>(
      'loadTrips emits TripLoading and TripLoaded',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1, trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      act: (cubit) => cubit.loadTrips(),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
    );

    blocTest<TripCubit, TripState>(
      'addTrip adds trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async => const Success(null));
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      act: (cubit) => cubit.addTrip(name: 'New Trip', startDate: DateTime.now()),
      expect: () => [
        const TripLoading(), // addTrip calls loadTrips internally?
        // addTrip implementation:
        // await repo.add; if active: await setActive.
        // setActive calls loadTrips.
        // loadTrips emits Loading, then Loaded.

        // Wait, if addTrip calls loadTrips...
        // Expect: Loading, Loaded.
        isA<TripLoaded>(),
      ],
      verify: (_) {
        verify(() => mockTripRepository.addTrip(any())).called(1);
        verify(() => mockTripRepository.setActiveTrip(any())).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'importTrip adds trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      act: (cubit) => cubit.importTrip(trip2),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.addTrip(trip2)).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'setActiveTrip calls repo and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1, trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      act: (cubit) => cubit.setActiveTrip('trip2'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.setActiveTrip('trip2')).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'deleteTrip deletes trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip2])); // After delete
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));
        when(() => mockTripRepository.deleteTrip(any())).thenAnswer((_) async => const Success(null));
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      seed: () => TripLoaded(trips: [trip1, trip2], activeTrip: trip2), // Start with state
      act: (cubit) => cubit.deleteTrip('trip1'),
      expect: () => [const TripLoading(), isA<TripLoaded>()], // Should just reload
      verify: (_) {
        verify(() => mockTripRepository.deleteTrip('trip1')).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'deleteTrip switches active trip if active trip is deleted',
      build: () {
        // Initial: [trip1, trip2], active: trip1
        // Action: delete trip1
        // Logic: Should switch to trip2, then delete trip1

        // Mock sequence for getAllTrips:
        // 1. Called during auto-switch logic? No, internal switch uses ID.
        // 2. Called at end (loadTrips).
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip2]));

        // Mock logic for setActiveTrip (logic searches otherTrips.first -> trip2)
        when(() => mockTripRepository.setActiveTrip('trip2')).thenAnswer((_) async => const Success(null));

        when(() => mockTripRepository.deleteTrip('trip1')).thenAnswer((_) async => const Success(null));

        // End state active trip
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip2));

        return TripCubit(
          tripRepository: mockTripRepository,
          syncService: mockSyncService,
          authService: mockAuthService,
        );
      },
      seed: () => TripLoaded(trips: [trip1, trip2], activeTrip: trip1),
      act: (cubit) => cubit.deleteTrip('trip1'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        // Verify implicit switch
        verify(() => mockTripRepository.setActiveTrip('trip2')).called(1);
        verify(() => mockTripRepository.deleteTrip('trip1')).called(1);
      },
    );

    test('uploadFullTrip gathers data and calls repo', () async {
      // Setup
      when(() => mockItineraryRepository.getAllItems()).thenReturn([]);
      when(() => mockGearRepository.getAllItems()).thenReturn([]);
      when(
        () => mockTripRepository.uploadFullTrip(
          trip: any(named: 'trip'),
          itineraryItems: any(named: 'itineraryItems'),
          gearItems: any(named: 'gearItems'),
        ),
      ).thenAnswer((_) async => const Success('mock-id'));

      final cubit = TripCubit(
        tripRepository: mockTripRepository,
        syncService: mockSyncService,
        authService: mockAuthService,
      );

      final result = await cubit.uploadFullTrip(trip1);

      expect(result, true);
      verify(() => mockTripRepository.uploadFullTrip(trip: trip1, itineraryItems: [], gearItems: [])).called(1);
    });

    test('loadTrips emits TripError on failure', () async {
      when(
        () => mockTripRepository.getAllTrips(any()),
      ).thenAnswer((_) async => Failure(GeneralException('Load failed')));

      final cubit = TripCubit(
        tripRepository: mockTripRepository,
        syncService: mockSyncService,
        authService: mockAuthService,
      );

      expectLater(cubit.stream, emitsInOrder([const TripLoading(), isA<TripError>()]));

      await cubit.loadTrips();
      await cubit.close();
    });
  });
}
