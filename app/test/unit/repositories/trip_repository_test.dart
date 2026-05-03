import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/trip_repository.dart';
import 'package:summitmate/core/error/result.dart';

// Mocks
class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

void main() {
  late TripRepository repository;
  late MockTripLocalDataSource mockLocalDataSource;
  late MockTripRemoteDataSource mockRemoteDataSource;

  late Trip testTrip;

  setUpAll(() {
    testTrip = Trip(
      id: 'trip_1',
      userId: 'user_1',
      name: 'Test Trip',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'user_1',
      updatedAt: DateTime.now(),
      updatedBy: 'user_1',
    );

    registerFallbackValue(testTrip);
  });

  setUp(() {
    mockLocalDataSource = MockTripLocalDataSource();
    mockRemoteDataSource = MockTripRemoteDataSource();
    repository = TripRepository(mockLocalDataSource, mockRemoteDataSource);
  });

  group('TripRepository', () {
    test('getAllTrips delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getAllTrips()).thenAnswer((_) async => [testTrip]);
      final result = await repository.getAllTrips('user_1');
      expect(result, isA<Success>());
      expect((result as Success).value, [testTrip]);
      verify(() => mockLocalDataSource.getAllTrips()).called(1);
    });

    test('getTripById delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getTripById('trip_1')).thenAnswer((_) async => testTrip);
      final result = await repository.getTripById('trip_1');
      expect(result, isA<Success>());
      expect((result as Success).value, testTrip);
      verify(() => mockLocalDataSource.getTripById('trip_1')).called(1);
    });

    test('deleteTrip delegates to localDataSource', () async {
      when(() => mockLocalDataSource.deleteTrip('trip_1')).thenAnswer((_) async => {});
      await repository.deleteTrip('trip_1');
      verify(() => mockLocalDataSource.deleteTrip('trip_1')).called(1);
    });

    test('Negative: getTripById returns null if not found', () async {
      when(() => mockLocalDataSource.getTripById('unknown')).thenAnswer((_) async => null);
      final result = await repository.getTripById('unknown');
      expect(result, isA<Success>());
      expect((result as Success).value, isNull);
    });

    test('Positive: getRemoteTrips fetches from remote and returns PaginatedList', () async {
      const paginated = PaginatedList<Trip>(items: [], page: 1, total: 0, hasMore: false);
      when(
        () => mockRemoteDataSource.getRemoteTrips(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => const Success(paginated));

      final result = await repository.getRemoteTrips();

      expect(result, isA<Success>());
      final value = (result as Success<PaginatedList<Trip>, Exception>).value;
      expect(value.items, isEmpty);
      expect(value.hasMore, false);
      verify(
        () => mockRemoteDataSource.getRemoteTrips(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        ),
      ).called(1);
    });

    test('Extreme: getAllTrips handles large number of trips', () async {
      final manyTrips = List.generate(
        100,
        (i) => Trip(
          id: 't_$i',
          userId: 'u1',
          name: 'Trip $i',
          startDate: DateTime.now().add(Duration(days: i)),
          createdAt: DateTime.now(),
          createdBy: 'u1',
          updatedAt: DateTime.now(),
          updatedBy: 'u1',
        ),
      );
      when(() => mockLocalDataSource.getAllTrips()).thenAnswer((_) async => manyTrips);

      final result = await repository.getAllTrips('u1');

      expect(result, isA<Success>());
      final trips = (result as Success).value as List<Trip>;
      expect(trips.length, 100);
      // Repository sorts by startDate DESC
      expect(trips[0].name, 'Trip 99');
    });
  });
}
