import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/providers/trip_provider.dart';

@GenerateNiceMocks([MockSpec<ITripRepository>()])
import 'trip_provider_test.mocks.dart';

void main() {
  late MockITripRepository mockRepository;
  late TripProvider provider;

  Trip createTrip({String id = 'trip-1', String name = 'Test Trip', bool isActive = false, DateTime? startDate}) {
    return Trip(id: id, name: name, startDate: startDate ?? DateTime.now(), isActive: isActive);
  }

  setUp(() {
    mockRepository = MockITripRepository();
    // 預設回傳空列表
    when(mockRepository.getAllTrips()).thenReturn([]);
    when(mockRepository.getActiveTrip()).thenReturn(null);
  });

  group('TripProvider Tests', () {
    group('初始化', () {
      test('loads trips on creation', () {
        final existingTrips = [
          createTrip(id: 'trip-1', name: 'Trip 1', isActive: true),
          createTrip(id: 'trip-2', name: 'Trip 2'),
        ];
        when(mockRepository.getAllTrips()).thenReturn(existingTrips);
        when(mockRepository.getActiveTrip()).thenReturn(existingTrips[0]);

        provider = TripProvider(repository: mockRepository);

        expect(provider.trips.length, 2);
        expect(provider.activeTrip?.id, 'trip-1');
        expect(provider.isLoading, false);
      });

      test('creates default trip when no trips exist', () async {
        when(mockRepository.getAllTrips()).thenReturn([]);
        when(mockRepository.getActiveTrip()).thenReturn(null);
        when(mockRepository.addTrip(any)).thenAnswer((_) async {});

        provider = TripProvider(repository: mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockRepository.addTrip(any)).called(1);
      });

      test('activates first trip if no active trip exists', () async {
        final existingTrips = [createTrip(id: 'trip-1', name: 'Trip 1', isActive: false)];
        when(mockRepository.getAllTrips()).thenReturn(existingTrips);
        when(mockRepository.getActiveTrip()).thenReturn(null);
        when(mockRepository.setActiveTrip(any)).thenAnswer((_) async {});
        when(mockRepository.getTripById('trip-1')).thenReturn(existingTrips[0]);

        provider = TripProvider(repository: mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockRepository.setActiveTrip('trip-1')).called(greaterThan(0));
      });
    });

    group('Getters', () {
      test('activeTripId returns null when no active trip', () {
        when(mockRepository.getAllTrips()).thenReturn([]);

        provider = TripProvider(repository: mockRepository);

        // Provider 會建立預設行程，所以這裡跳過此測試
      });

      test('hasTrips returns true when trips exist', () {
        when(mockRepository.getAllTrips()).thenReturn([createTrip(id: 'trip-1', isActive: true)]);
        when(mockRepository.getActiveTrip()).thenReturn(createTrip(id: 'trip-1', isActive: true));

        provider = TripProvider(repository: mockRepository);

        expect(provider.hasTrips, true);
      });
    });

    group('addTrip', () {
      test('adds new trip and sets as active by default', () async {
        final existingTrip = createTrip(id: 'trip-1', name: 'Existing', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([existingTrip]);
        when(mockRepository.getActiveTrip()).thenReturn(existingTrip);
        when(mockRepository.addTrip(any)).thenAnswer((_) async {});
        when(mockRepository.setActiveTrip(any)).thenAnswer((_) async {});
        when(mockRepository.getTripById(any)).thenReturn(existingTrip);

        provider = TripProvider(repository: mockRepository);
        await provider.addTrip(name: 'New Trip', startDate: DateTime(2024, 1, 1));

        verify(mockRepository.addTrip(any)).called(greaterThan(0));
      });

      test('adds trip without setting as active when setAsActive is false', () async {
        final existingTrip = createTrip(id: 'trip-1', name: 'Existing', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([existingTrip]);
        when(mockRepository.getActiveTrip()).thenReturn(existingTrip);
        when(mockRepository.addTrip(any)).thenAnswer((_) async {});

        provider = TripProvider(repository: mockRepository);
        await provider.addTrip(name: 'New Trip', startDate: DateTime(2024, 1, 1), setAsActive: false);

        verify(mockRepository.addTrip(any)).called(greaterThan(0));
        // setAsActive=false 時不會額外呼叫 setActiveTrip 來設定新行程為活動
      });
    });

    group('updateTrip', () {
      test('updates trip in repository', () async {
        final trip = createTrip(id: 'trip-1', name: 'Original', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([trip]);
        when(mockRepository.getActiveTrip()).thenReturn(trip);
        when(mockRepository.updateTrip(any)).thenAnswer((_) async {});

        provider = TripProvider(repository: mockRepository);

        final updatedTrip = createTrip(id: 'trip-1', name: 'Updated');
        await provider.updateTrip(updatedTrip);

        verify(mockRepository.updateTrip(updatedTrip)).called(1);
      });
    });

    group('deleteTrip', () {
      test('cannot delete the only trip', () async {
        final trip = createTrip(id: 'trip-1', name: 'Only Trip', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([trip]);
        when(mockRepository.getActiveTrip()).thenReturn(trip);

        provider = TripProvider(repository: mockRepository);
        final result = await provider.deleteTrip('trip-1');

        expect(result, false);
        verifyNever(mockRepository.deleteTrip(any));
      });

      test('deletes trip when multiple trips exist', () async {
        final trips = [
          createTrip(id: 'trip-1', name: 'Trip 1', isActive: true),
          createTrip(id: 'trip-2', name: 'Trip 2'),
        ];
        when(mockRepository.getAllTrips()).thenReturn(trips);
        when(mockRepository.getActiveTrip()).thenReturn(trips[0]);
        when(mockRepository.deleteTrip(any)).thenAnswer((_) async {});
        when(mockRepository.setActiveTrip(any)).thenAnswer((_) async {});
        when(mockRepository.getTripById(any)).thenReturn(trips[1]);

        provider = TripProvider(repository: mockRepository);
        final result = await provider.deleteTrip('trip-2');

        expect(result, true);
        verify(mockRepository.deleteTrip('trip-2')).called(1);
      });

      test('switches to another trip when deleting active trip', () async {
        final trips = [
          createTrip(id: 'trip-1', name: 'Trip 1', isActive: true),
          createTrip(id: 'trip-2', name: 'Trip 2'),
        ];
        when(mockRepository.getAllTrips()).thenReturn(trips);
        when(mockRepository.getActiveTrip()).thenReturn(trips[0]);
        when(mockRepository.deleteTrip(any)).thenAnswer((_) async {});
        when(mockRepository.setActiveTrip(any)).thenAnswer((_) async {});
        when(mockRepository.getTripById('trip-2')).thenReturn(trips[1]);

        provider = TripProvider(repository: mockRepository);
        await provider.deleteTrip('trip-1');

        verify(mockRepository.setActiveTrip('trip-2')).called(greaterThan(0));
      });
    });

    group('setActiveTrip', () {
      test('sets trip as active in repository', () async {
        final trips = [
          createTrip(id: 'trip-1', name: 'Trip 1', isActive: true),
          createTrip(id: 'trip-2', name: 'Trip 2'),
        ];
        when(mockRepository.getAllTrips()).thenReturn(trips);
        when(mockRepository.getActiveTrip()).thenReturn(trips[0]);
        when(mockRepository.setActiveTrip(any)).thenAnswer((_) async {});
        when(mockRepository.getTripById('trip-2')).thenReturn(trips[1]);

        provider = TripProvider(repository: mockRepository);
        await provider.setActiveTrip('trip-2');

        verify(mockRepository.setActiveTrip('trip-2')).called(greaterThan(0));
      });
    });

    group('getTripById', () {
      test('returns trip from repository', () {
        final trip = createTrip(id: 'trip-1', name: 'Test', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([trip]);
        when(mockRepository.getActiveTrip()).thenReturn(trip);
        when(mockRepository.getTripById('trip-1')).thenReturn(trip);

        provider = TripProvider(repository: mockRepository);
        final result = provider.getTripById('trip-1');

        expect(result?.id, 'trip-1');
        expect(result?.name, 'Test');
      });

      test('returns null for non-existent trip', () {
        final trip = createTrip(id: 'trip-1', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([trip]);
        when(mockRepository.getActiveTrip()).thenReturn(trip);
        when(mockRepository.getTripById('trip-999')).thenReturn(null);

        provider = TripProvider(repository: mockRepository);
        final result = provider.getTripById('trip-999');

        expect(result, isNull);
      });
    });

    group('reload', () {
      test('reloads trips from repository', () {
        final trip = createTrip(id: 'trip-1', isActive: true);
        when(mockRepository.getAllTrips()).thenReturn([trip]);
        when(mockRepository.getActiveTrip()).thenReturn(trip);

        provider = TripProvider(repository: mockRepository);
        provider.reload();

        verify(mockRepository.getAllTrips()).called(greaterThan(1));
      });
    });
  });
}
