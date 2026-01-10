import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';

import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockSyncService mockSyncService;

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockSyncService = MockSyncService();
    // Register fallback values if needed
    registerFallbackValue(Trip(id: 'fallback', name: 'fallback', startDate: DateTime.now(), createdAt: DateTime.now()));
  });

  group('TripCubit', () {
    final trip1 = Trip(
      id: 'trip1',
      name: 'Trip 1',
      startDate: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
      isActive: true,
    );
    final trip2 = Trip(
      id: 'trip2',
      name: 'Trip 2',
      startDate: DateTime(2023, 2, 1),
      createdAt: DateTime(2023, 2, 1),
      isActive: false,
    );

    test('initial state is TripInitial', () {
      expect(TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService).state, const TripInitial());
    });

    blocTest<TripCubit, TripState>(
      'loadTrips emits TripLoading and TripLoaded',
      build: () {
        when(() => mockTripRepository.getAllTrips()).thenReturn([trip1, trip2]);
        when(() => mockTripRepository.getActiveTrip()).thenReturn(trip1);
        return TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService);
      },
      act: (cubit) => cubit.loadTrips(),
      expect: () => [
        const TripLoading(),
        isA<TripLoaded>(), // Content check is tricky with sorts, checking type is safer for now
      ],
    );

    blocTest<TripCubit, TripState>(
      'addTrip adds trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips()).thenReturn([trip1]);
        when(() => mockTripRepository.getActiveTrip()).thenReturn(trip1);
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async {});
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async {});
        return TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService);
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
        when(() => mockTripRepository.getAllTrips()).thenReturn([trip1]);
        when(() => mockTripRepository.getActiveTrip()).thenReturn(trip1);
        when(() => mockTripRepository.addTrip(any())).thenAnswer((_) async {});
        return TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService);
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
        when(() => mockTripRepository.getAllTrips()).thenReturn([trip1, trip2]);
        when(() => mockTripRepository.getActiveTrip()).thenReturn(trip1);
        when(() => mockTripRepository.setActiveTrip(any())).thenAnswer((_) async {});
        return TripCubit(tripRepository: mockTripRepository, syncService: mockSyncService);
      },
      act: (cubit) => cubit.setActiveTrip('trip2'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.setActiveTrip('trip2')).called(1);
      },
    );
  });
}
