import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

Map<String, dynamic> createUserJson({
  String id = 'test-uuid',
  String email = 'test@example.com',
  String name = 'Test User',
  String avatar = '🐻',
}) {
  return {'id': id, 'email': email, 'display_name': name, 'avatar': avatar};
}

void main() {
  late TripRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = TripRemoteDataSource(apiClient: mockApiClient);
  });

  final testTrip = Trip(
    id: 'trip-123',
    userId: 'user-456',
    name: 'Test Trip',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 5),
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-456',
    updatedAt: DateTime(2024, 1, 1),
    updatedBy: 'user-456',
  );

  group('TripRemoteDataSource.getTrips', () {
    test('returns list of trips on success', () async {
      final tripJson = [
        {
          'id': 'trip-123',
          'user_id': 'user-456',
          'name': 'Test Trip',
          'start_date': '2024-01-01T00:00:00.000Z',
          'end_date': '2024-01-05T00:00:00.000Z',
          'created_at': '2024-01-01T00:00:00.000Z',
          'created_by': 'user-456',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'updated_by': 'user-456',
          'is_active': true,
        },
      ];

      when(() => mockApiClient.get('/trips')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips'),
          data: tripJson,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getTrips();

      expect(result.length, 1);
      expect(result[0].id, 'trip-123');
      expect(result[0].name, 'Test Trip');
    });

    test('throws exception on non-200 status', () async {
      when(
        () => mockApiClient.get('/trips'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/trips'), statusCode: 500));

      expect(() => dataSource.getTrips(), throwsException);
    });
  });

  group('TripRemoteDataSource.uploadTrip', () {
    test('returns new trip ID on success', () async {
      when(() => mockApiClient.post('/trips', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips'),
          data: {'id': 'new-trip-id'},
          statusCode: 201,
        ),
      );

      final result = await dataSource.uploadTrip(testTrip);

      expect(result, 'new-trip-id');
      verify(() => mockApiClient.post('/trips', data: any(named: 'data'))).called(1);
    });
  });

  group('TripRemoteDataSource.updateTrip', () {
    test('calls put and returns normally on success', () async {
      when(() => mockApiClient.put('/trips/${testTrip.id}', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/trips/${testTrip.id}'), statusCode: 200),
      );

      await dataSource.updateTrip(testTrip);

      verify(() => mockApiClient.put('/trips/${testTrip.id}', data: any(named: 'data'))).called(1);
    });
  });

  group('TripRemoteDataSource.deleteTrip', () {
    test('calls delete and returns normally on success', () async {
      when(
        () => mockApiClient.delete('/trips/trip-123'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/trips/trip-123'), statusCode: 204));

      await dataSource.deleteTrip('trip-123');

      verify(() => mockApiClient.delete('/trips/trip-123')).called(1);
    });
  });

  group('Member Operations', () {
    test('searchUserByEmail returns UserProfile on success', () async {
      final userJson = createUserJson(id: 'user-123', email: 'test@example.com', name: 'Test User');

      when(() => mockApiClient.get('/users/search', queryParameters: {'email': 'test@example.com'})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/users/search'),
          data: userJson,
          statusCode: 200,
        ),
      );

      final result = await dataSource.searchUserByEmail('test@example.com');

      expect(result.id, 'user-123');
      expect(result.displayName, 'Test User');
    });

    test('addMemberByEmail calls post correctly', () async {
      when(() => mockApiClient.post('/trips/trip-1/members', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/trips/trip-1/members'), statusCode: 201),
      );

      await dataSource.addMemberByEmail('trip-1', 'new@example.com');

      verify(
        () => mockApiClient.post('/trips/trip-1/members', data: {'email': 'new@example.com', 'role': 'member'}),
      ).called(1);
    });
  });
}
