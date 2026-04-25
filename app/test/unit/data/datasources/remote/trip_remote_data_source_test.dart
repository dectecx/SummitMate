import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/trip_api_models.dart';
import 'package:summitmate/data/api/models/user_api_models.dart';
import 'package:summitmate/data/api/services/trip_api_service.dart';
import 'package:summitmate/data/api/services/user_api_service.dart';
import 'package:summitmate/data/datasources/remote/trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';

class MockTripApiService extends Mock implements TripApiService {}

class MockUserApiService extends Mock implements UserApiService {}

class FakeTripCreateRequest extends Fake implements TripCreateRequest {}

class FakeTripUpdateRequest extends Fake implements TripUpdateRequest {}

class FakeAddMemberRequest extends Fake implements AddMemberRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripCreateRequest());
    registerFallbackValue(FakeTripUpdateRequest());
    registerFallbackValue(FakeAddMemberRequest());
  });

  late TripRemoteDataSource dataSource;
  late MockTripApiService mockTripApi;
  late MockUserApiService mockUserApi;

  setUp(() {
    mockTripApi = MockTripApiService();
    mockUserApi = MockUserApiService();
    dataSource = TripRemoteDataSource(mockTripApi, mockUserApi);
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

  final testUserResponse = UserResponse.fromJson({
    'id': 'user-456',
    'email': 'test@example.com',
    'display_name': 'Test User',
    'avatar': '🐻',
    'role': 'member',
    'permissions': [],
    'is_verified': true,
  });

  group('TripRemoteDataSource', () {
    test('getTrips returns list of trips on success', () async {
      final paginationResponse = TripListPaginationResponse.fromJson({
        'items': [
          {
            'id': 'trip-123',
            'user_id': 'user-456',
            'name': 'Test Trip',
            'start_date': '2024-01-01',
            'end_date': '2024-01-05',
            'is_active': true,
          }
        ],
        'pagination': {'next_cursor': null, 'has_more': false},
      });
      when(() => mockTripApi.listTrips()).thenAnswer((_) async => paginationResponse);

      final result = await dataSource.getTrips();

      expect(result.items.length, 1);
      expect(result.items.first.id, 'trip-123');
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
      expect(result, 'trip-123');
    });

    test('addMemberById searches user and then adds member', () async {
      when(() => mockUserApi.getUserById('user-456')).thenAnswer((_) async => testUserResponse);
      when(() => mockTripApi.addMember('trip-123', any())).thenAnswer((_) async => {});

      await dataSource.addMemberById('trip-123', 'user-456');

      verify(() => mockUserApi.getUserById('user-456')).called(1);
      verify(() => mockTripApi.addMember('trip-123', any())).called(1);
    });

    test('searchUserByEmail calls UserApiService', () async {
      when(() => mockUserApi.searchUserByEmail('test@example.com')).thenAnswer((_) async => testUserResponse);

      final result = await dataSource.searchUserByEmail('test@example.com');

      expect(result.email, 'test@example.com');
      verify(() => mockUserApi.searchUserByEmail('test@example.com')).called(1);
    });
  });
}
