import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/itinerary_api_models.dart';
import 'package:summitmate/data/api/services/itinerary_api_service.dart';
import 'package:summitmate/data/datasources/remote/itinerary_remote_data_source.dart';

class MockItineraryApiService extends Mock implements ItineraryApiService {}

class FakeItineraryItemRequest extends Fake implements ItineraryItemRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItineraryItemRequest());
  });

  late ItineraryRemoteDataSource dataSource;
  late MockItineraryApiService mockApiService;

  setUp(() {
    mockApiService = MockItineraryApiService();
    dataSource = ItineraryRemoteDataSource(mockApiService);
  });

  final testResponse = ItineraryItemResponse.fromJson({
    'id': '1',
    'trip_id': 'trip-1',
    'day': 'D1',
    'name': 'Trailhead',
    'est_time': '08:00',
    'altitude': 2000,
    'distance': 0.0,
    'note': 'Start',
    'is_checked_in': false,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  });

  group('ItineraryRemoteDataSource.getItinerary', () {
    test('returns list of itinerary items on success', () async {
      when(() => mockApiService.listItinerary('trip-1')).thenAnswer((_) async => [testResponse]);

      final result = await dataSource.getItinerary('trip-1');

      expect(result.length, 1);
      expect(result[0].id, '1');
      expect(result[0].name, 'Trailhead');
    });

    test('throws exception on error', () async {
      when(() => mockApiService.listItinerary('fail')).thenThrow(Exception('Error'));

      expect(() => dataSource.getItinerary('fail'), throwsException);
    });
  });
}
