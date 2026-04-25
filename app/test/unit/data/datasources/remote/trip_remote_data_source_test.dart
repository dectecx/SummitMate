import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/trip_api_models.dart';
import 'package:summitmate/data/api/services/trip_api_service.dart';
import 'package:summitmate/data/datasources/remote/trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';

class MockDio extends Mock implements Dio {}
class MockTripApiService extends Mock implements TripApiService {}
class FakeTripCreateRequest extends Fake implements TripCreateRequest {}
class FakeTripUpdateRequest extends Fake implements TripUpdateRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripCreateRequest());
    registerFallbackValue(FakeTripUpdateRequest());
  });

  late TripRemoteDataSource dataSource;
  late MockDio mockDio;
  late MockTripApiService mockTripApi;

  setUp(() {
    mockDio = MockDio();
    mockTripApi = MockTripApiService();
    dataSource = TripRemoteDataSource(mockTripApi, mockDio);
  });

  final testTripResponse = TripResponse.fromJson({
    'id': 'trip-123',
    'user_id': 'user-456',
    'name': 'Test Trip',
    'start_date': '2024-01-01',
    'end_date': '2024-01-05',
    'is_active': true,
    'day_names': [],
    'created_at': '2024-01-01T00:00:00Z',
    'created_by': 'user-456',
    'updated_at': '2024-01-01T00:00:00Z',
    'updated_by': 'user-456',
  });

  group('TripRemoteDataSource', () {
    test('getTrips returns list of trips on success', () async {
      when(() => mockTripApi.listTrips()).thenAnswer((_) async => [testTripResponse]);

      final result = await dataSource.getTrips();

      expect(result.length, 1);
      expect(result.first.id, 'trip-123');
      expect(result.first.name, 'Test Trip');
    });



    test('uploadTrip returns new id on success', () async {
      when(() => mockTripApi.createTrip(any())).thenAnswer((_) async => testTripResponse);

      final trip = Trip(
        id: 'new-id',
        userId: 'u1',
        name: 'New',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'u1',
        updatedAt: DateTime(2024, 1, 1),
        updatedBy: 'u1',
      );

      final result = await dataSource.uploadTrip(trip);
      expect(result, 'trip-123');
    });

    test('updateTrip calls api correctly', () async {
      when(() => mockTripApi.updateTrip('trip-123', any())).thenAnswer((_) async => testTripResponse);

      final trip = Trip(
        id: 'trip-123',
        userId: 'u1',
        name: 'New',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'u1',
        updatedAt: DateTime(2024, 1, 1),
        updatedBy: 'u1',
      );

      await dataSource.updateTrip(trip);
      verify(() => mockTripApi.updateTrip('trip-123', any())).called(1);
    });

    test('deleteTrip calls api correctly', () async {
      when(() => mockTripApi.deleteTrip('trip-123')).thenAnswer((_) async {});

      await dataSource.deleteTrip('trip-123');
      verify(() => mockTripApi.deleteTrip('trip-123')).called(1);
    });
  });
}
