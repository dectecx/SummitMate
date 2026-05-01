import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/trip_api_models.dart';
import 'package:summitmate/data/api/services/trip_api_service.dart';
import 'package:summitmate/data/datasources/remote/trip_remote_data_source.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/core/error/result.dart';

class MockTripApiService extends Mock implements TripApiService {}

class FakeTripCreateRequest extends Fake implements TripCreateRequest {}

class FakeTripUpdateRequest extends Fake implements TripUpdateRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripCreateRequest());
    registerFallbackValue(FakeTripUpdateRequest());
  });

  late TripRemoteDataSource dataSource;
  late MockTripApiService mockTripApi;

  setUp(() {
    mockTripApi = MockTripApiService();
    dataSource = TripRemoteDataSource(mockTripApi);
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
    test('getRemoteTrips returns list of trips on success', () async {
      final paginationResponse = TripListPaginationResponse.fromJson({
        'items': [
          {
            'id': 'trip-123',
            'user_id': 'user-456',
            'name': 'Test Trip',
            'start_date': '2024-01-01',
            'end_date': '2024-01-05',
            'is_active': true,
            'created_at': '2024-01-01T00:00:00Z',
            'created_by': 'user-456',
            'updated_at': '2024-01-01T00:00:00Z',
            'updated_by': 'user-456',
          },
        ],
        'pagination': {'next_cursor': null, 'has_more': false, 'page': 1, 'limit': 20, 'total': 1},
      });
      when(
        () => mockTripApi.listTrips(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => paginationResponse);

      final result = await dataSource.getRemoteTrips();

      expect(result, isA<Success>());
      final paginated = (result as Success).value;
      expect(paginated.items.length, 1);
      expect(paginated.items.first.id, 'trip-123');
    });

    test('uploadTrip returns new id on success', () async {
      when(() => mockTripApi.createTrip(any())).thenAnswer((_) async => testTripResponse);

      final trip = Trip.fromJson({
        'id': 'new-id',
        'user_id': 'u1',
        'name': 'New',
        'start_date': '2024-01-01T00:00:00Z',
        'end_date': '2024-01-05T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
        'created_by': 'u1',
        'updated_at': '2024-01-01T00:00:00Z',
        'updated_by': 'u1',
      });

      final result = await dataSource.uploadTrip(trip);
      expect(result, isA<Success>());
      expect((result as Success).value, 'trip-123');
    });

    test('deleteTrip calls api', () async {
      when(() => mockTripApi.deleteTrip('trip-123')).thenAnswer((_) async {});

      final result = await dataSource.deleteTrip('trip-123');

      expect(result, isA<Success>());
      verify(() => mockTripApi.deleteTrip('trip-123')).called(1);
    });

    test('getTripDetails returns trip on success', () async {
      when(() => mockTripApi.getTrip('trip-123')).thenAnswer((_) async => testTripResponse);

      final result = await dataSource.getTripDetails('trip-123');

      expect(result, isA<Success>());
      expect((result as Success).value.id, 'trip-123');
    });
  });
}
