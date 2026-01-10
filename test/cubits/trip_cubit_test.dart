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
  group('TripCubit', () {
    late TripCubit tripCubit;
    late MockTripRepository mockTripRepo;
    late MockSyncService mockSyncService;

    final trip1 = Trip(id: 't1', name: 'Trip 1', startDate: DateTime.now(), isActive: true);

    setUpAll(() {
      registerFallbackValue(trip1);
    });

    setUp(() {
      mockTripRepo = MockTripRepository();
      mockSyncService = MockSyncService();

      when(() => mockTripRepo.getAllTrips()).thenReturn([trip1]);
      when(() => mockTripRepo.getActiveTrip()).thenReturn(trip1);
      when(() => mockTripRepo.addTrip(any())).thenAnswer((_) async {});
      when(() => mockTripRepo.setActiveTrip(any())).thenAnswer((_) async {});
      when(() => mockTripRepo.deleteTrip(any())).thenAnswer((_) async {});

      tripCubit = TripCubit(tripRepository: mockTripRepo, syncService: mockSyncService);
    });

    tearDown(() {
      tripCubit.close();
    });

    test('initial state is TripInitial', () {
      expect(tripCubit.state, isA<TripInitial>());
    });

    blocTest<TripCubit, TripState>(
      'loadTrips loads from repo',
      build: () => tripCubit,
      act: (cubit) => cubit.loadTrips(),
      expect: () => [
        isA<TripLoading>(),
        isA<TripLoaded>()
            .having((s) => s.trips.length, 'trips count', 1)
            .having((s) => s.activeTrip?.id, 'active trip id', 't1'),
      ],
    );

    blocTest<TripCubit, TripState>(
      'addTrip calls repo',
      build: () => tripCubit,
      act: (cubit) => cubit.addTrip(name: 'New Trip', startDate: DateTime.now()),
      verify: (_) {
        verify(() => mockTripRepo.addTrip(any())).called(1);
        verify(() => mockTripRepo.setActiveTrip(any())).called(1); // setAsActive defaults to true
      },
    );
  });
}
