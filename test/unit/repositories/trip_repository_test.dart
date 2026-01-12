import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';

// Mocks
class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late TripRepository repository;
  late MockTripLocalDataSource mockLocalDataSource;
  late MockTripRemoteDataSource mockRemoteDataSource;

  late Trip testTrip;

  setUp(() {
    mockLocalDataSource = MockTripLocalDataSource();
    mockRemoteDataSource = MockTripRemoteDataSource();
    repository = TripRepository(localDataSource: mockLocalDataSource, remoteDataSource: mockRemoteDataSource);

    testTrip = Trip(
      id: 'trip_1',
      userId: 'user_1',
      name: 'Test Trip',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'user_1',
    );

    // Register fallback values for mocktail if needed
    registerFallbackValue(testTrip);
  });

  group('TripRepository', () {
    test('init calls localDataSource.init', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});

      await repository.init();

      verify(() => mockLocalDataSource.init()).called(1);
    });

    test('getAllTrips delegates to localDataSource', () {
      when(() => mockLocalDataSource.getAllTrips()).thenReturn([testTrip]);
      final result = repository.getAllTrips('user_1');
      expect(result, [testTrip]);
      verify(() => mockLocalDataSource.getAllTrips()).called(1);
    });

    test('getTripById delegates to localDataSource', () {
      when(() => mockLocalDataSource.getTripById('trip_1')).thenReturn(testTrip);
      final result = repository.getTripById('trip_1');
      expect(result, testTrip);
      verify(() => mockLocalDataSource.getTripById('trip_1')).called(1);
    });

    test('deleteTrip delegates to localDataSource', () async {
      when(() => mockLocalDataSource.deleteTrip('trip_1')).thenAnswer((_) async {});
      await repository.deleteTrip('trip_1');
      verify(() => mockLocalDataSource.deleteTrip('trip_1')).called(1);
    });
  });
}
