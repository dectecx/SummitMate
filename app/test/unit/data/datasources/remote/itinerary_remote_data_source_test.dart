import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/itinerary_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ItineraryRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = ItineraryRemoteDataSource(mockDio);
  });

  group('ItineraryRemoteDataSource.getItinerary', () {
    test('returns list of itinerary items on success', () async {
      final tripId = 'trip-1';
      final responseData = [
        {
          'id': 'item-1',
          'trip_id': tripId,
          'day': 'D1',
          'name': 'Start Hiking',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      when(() => mockDio.get('/trips/$tripId/itinerary')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/$tripId/itinerary'),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getItinerary(tripId);

      expect(result.length, 1);
      expect(result[0].id, 'item-1');
      expect(result[0].name, 'Start Hiking');
      verify(() => mockDio.get('/trips/$tripId/itinerary')).called(1);
    });

    test('throws exception on error', () async {
      final tripId = 'fail';
      when(() => mockDio.get('/trips/$tripId/itinerary')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/$tripId/itinerary'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/trips/$tripId/itinerary'),
            statusCode: 404,
          ),
        ),
      );

      expect(() => dataSource.getItinerary(tripId), throwsA(isA<DioException>()));
    });
  });
}
