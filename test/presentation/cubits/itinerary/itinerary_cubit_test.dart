import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/cubits/itinerary/itinerary_cubit.dart';
import 'package:summitmate/presentation/cubits/itinerary/itinerary_state.dart';

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  late IItineraryRepository mockItineraryRepository;
  late ITripRepository mockTripRepository;
  late ItineraryCubit cubit;

  final testTrip = Trip(
    id: 'trip_1',
    name: 'Test Trip',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 3)),
  );

  final testItem = ItineraryItem(uuid: 'item_1', tripId: 'trip_1', day: 'D1', name: 'Start Point', estTime: '08:00');

  setUp(() {
    mockItineraryRepository = MockItineraryRepository();
    mockTripRepository = MockTripRepository();

    // Default setup: active trip exists
    when(() => mockTripRepository.getActiveTrip()).thenReturn(testTrip);

    cubit = ItineraryCubit(repository: mockItineraryRepository, tripRepository: mockTripRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ItineraryCubit', () {
    test('initial state is ItineraryInitial', () {
      expect(cubit.state, const ItineraryInitial());
    });

    blocTest<ItineraryCubit, ItineraryState>(
      'loadItinerary emits [ItineraryLoading, ItineraryLoaded] with filtered items',
      setUp: () {
        when(() => mockItineraryRepository.getAllItems()).thenReturn([testItem]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadItinerary(),
      expect: () => [
        const ItineraryLoading(),
        isA<ItineraryLoaded>()
            .having((s) => s.items.length, 'items length', 1)
            .having((s) => s.items.first.tripId, 'tripId', 'trip_1'),
      ],
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'loadItinerary emits empty list when no active trip',
      setUp: () {
        when(() => mockTripRepository.getActiveTrip()).thenReturn(null);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadItinerary(),
      expect: () => [const ItineraryLoading(), isA<ItineraryLoaded>().having((s) => s.items, 'items', isEmpty)],
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'loadItinerary emits ItineraryError on failure',
      setUp: () {
        when(() => mockItineraryRepository.getAllItems()).thenThrow(Exception('DB Error'));
      },
      build: () => cubit,
      act: (cubit) => cubit.loadItinerary(),
      expect: () => [
        const ItineraryLoading(),
        isA<ItineraryError>().having((s) => s.message, 'message', contains('DB Error')),
      ],
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'selectDay updates selectedDay',
      setUp: () {
        when(() => mockItineraryRepository.getAllItems()).thenReturn([]);
      },
      build: () => cubit,
      seed: () => const ItineraryLoaded(items: [], selectedDay: 'D1'),
      act: (cubit) => cubit.selectDay('D2'),
      expect: () => [isA<ItineraryLoaded>().having((s) => s.selectedDay, 'selectedDay', 'D2')],
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'toggleEditMode updates isEditMode',
      build: () => cubit,
      seed: () => const ItineraryLoaded(items: [], isEditMode: false),
      act: (cubit) => cubit.toggleEditMode(),
      expect: () => [isA<ItineraryLoaded>().having((s) => s.isEditMode, 'isEditMode', true)], // expect
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'addItem calls repository and reloads',
      setUp: () {
        when(() => mockItineraryRepository.addItem(any())).thenAnswer((_) async {});
        when(() => mockItineraryRepository.getAllItems()).thenReturn([testItem]);
      },
      build: () => cubit,
      act: (cubit) => cubit.addItem(testItem),
      verify: (_) {
        verify(() => mockItineraryRepository.addItem(any())).called(1);
        verify(() => mockItineraryRepository.getAllItems()).called(1); // Reload called
      },
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'checkIn calls repository and reloads',
      setUp: () {
        when(() => mockItineraryRepository.checkIn(any(), any())).thenAnswer((_) async {});
        when(() => mockItineraryRepository.getAllItems()).thenReturn([testItem]);
      },
      build: () => cubit,
      act: (cubit) => cubit.checkIn('item_1'),
      verify: (_) {
        verify(() => mockItineraryRepository.checkIn('item_1', any())).called(1);
      },
    );

    blocTest<ItineraryCubit, ItineraryState>(
      'deleteItem calls repository and reloads',
      setUp: () {
        when(() => mockItineraryRepository.deleteItem(any())).thenAnswer((_) async {});
        when(() => mockItineraryRepository.getAllItems()).thenReturn([]);
      },
      build: () => cubit,
      act: (cubit) => cubit.deleteItem('item_1'),
      verify: (_) {
        verify(() => mockItineraryRepository.deleteItem('item_1')).called(1);
      },
    );
  });
}
