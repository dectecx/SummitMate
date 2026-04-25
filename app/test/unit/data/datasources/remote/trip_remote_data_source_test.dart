import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late TripRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions(baseUrl: 'http://localhost'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());
    dataSource = TripRemoteDataSource(mockDio);
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
          'start_date': '2024-01-01',
          'end_date': '2024-01-05',
          'created_at': '2024-01-01T00:00:00.000Z',
          'created_by': 'user-456',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'updated_by': 'user-456',
          'is_active': true,
          'day_names': [],
        },
      ];

      when(
        () => mockDio.get<List<dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
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
  });

  group('TripRemoteDataSource.deleteTrip', () {
    test('calls delete and returns normally on success', () async {
      when(
        () => mockDio.delete<dynamic>(
          '/trips/trip-123',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/trip-123'),
          statusCode: 204,
        ),
      );

      await dataSource.deleteTrip('trip-123');
    });
  });

  group('TripRemoteDataSource.updateTrip', () {
    test('calls patch and returns normally on success', () async {
      final responseJson = {
        'id': testTrip.id,
        'user_id': testTrip.userId,
        'name': testTrip.name,
        'start_date': '2024-01-01',
        'end_date': '2024-01-05',
        'created_at': '2024-01-01T00:00:00.000Z',
        'created_by': testTrip.createdBy,
        'updated_at': '2024-01-01T00:00:00.000Z',
        'updated_by': testTrip.updatedBy,
        'is_active': false,
        'day_names': [],
      };

      when(
        () => mockDio.patch<dynamic>(
          '/trips/${testTrip.id}',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
          data: responseJson,
          statusCode: 200,
        ),
      );

      await dataSource.updateTrip(testTrip);
    });
  });
}
