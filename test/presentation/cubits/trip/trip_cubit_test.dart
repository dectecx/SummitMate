import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';

import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';

import 'package:summitmate/domain/interfaces/i_auth_service.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockSyncService mockSyncService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockSyncService = MockSyncService();
    mockAuthService = MockAuthService();

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
        when(() => mockTripRepository.getAllTrips(any())).thenReturn([trip1, trip2]);
        when(() => mockTripRepository.getActiveTrip(any())).thenReturn(trip1);
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
        when(() => mockTripRepository.getAllTrips(any())).thenReturn([trip1]);
        when(() => mockTripRepository.getActiveTrip(any())).thenReturn(trip1);
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async {});
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async {});
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
        when(() => mockTripRepository.getAllTrips(any())).thenReturn([trip1]);
        when(() => mockTripRepository.getActiveTrip(any())).thenReturn(trip1);
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async {});
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
        when(() => mockTripRepository.getAllTrips(any())).thenReturn([trip1, trip2]);
        when(() => mockTripRepository.getActiveTrip(any())).thenReturn(trip1);
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async {});
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
  });
}
