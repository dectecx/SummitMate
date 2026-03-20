import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/itinerary_remote_data_source.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late ItineraryRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = ItineraryRemoteDataSource(apiClient: mockApiClient);
  });

  group('ItineraryRemoteDataSource.getItinerary', () {
    test('returns list of itinerary items on success', () async {
      final tripId = 'trip-1';
      final responseData = {
        'id': tripId,
        'itinerary': [
          {'id': 'item-1', 'trip_id': tripId, 'day': 'D1', 'name': 'Start Hiking'},
        ],
      };

      when(() => mockApiClient.get('/trips/$tripId')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/$tripId'),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getItinerary(tripId);

      expect(result.length, 1);
      expect(result[0].id, 'item-1');
      expect(result[0].name, 'Start Hiking');
    });

    test('returns empty list if itinerary field is null', () async {
      final tripId = 'trip-1';
      when(() => mockApiClient.get('/trips/$tripId')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/$tripId'),
          data: {'id': tripId, 'itinerary': null},
          statusCode: 200,
        ),
      );

      final result = await dataSource.getItinerary(tripId);
      expect(result, isEmpty);
    });

    test('throws exception on non-200 status', () async {
      when(
        () => mockApiClient.get('/trips/fail'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/trips/fail'), statusCode: 404));

      expect(() => dataSource.getItinerary('fail'), throwsException);
    });
  });
}
