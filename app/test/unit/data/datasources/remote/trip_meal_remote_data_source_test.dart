import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/trip_meal_remote_data_source.dart';
import 'package:summitmate/data/models/meal_item.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late TripMealRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = TripMealRemoteDataSource(apiClient: mockApiClient);
  });

  final testMeal = MealItem(id: 'meal-1', name: 'Rice', weight: 500, calories: 500);

  group('TripMealRemoteDataSource.getTripMeals', () {
    test('returns list of meal items on success', () async {
      final tripId = 'trip-1';
      final responseData = [testMeal.toJson()];

      when(() => mockApiClient.get('/trips/$tripId/meals')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getTripMeals(tripId);

      expect(result.length, 1);
      expect(result[0].name, 'Rice');
    });
  });

  group('TripMealRemoteDataSource CRUD', () {
    test('addTripMeal calls post and returns item', () async {
      final tripId = 'trip-1';
      when(() => mockApiClient.post('/trips/$tripId/meals', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: testMeal.toJson(),
          statusCode: 201,
        ),
      );

      final result = await dataSource.addTripMeal(tripId, testMeal);

      expect(result.name, 'Rice');
      verify(() => mockApiClient.post('/trips/$tripId/meals', data: any(named: 'data'))).called(1);
    });

    test('updateTripMeal calls put', () async {
      final tripId = 'trip-1';
      when(
        () => mockApiClient.put('/trips/$tripId/meals/${testMeal.id}', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

      await dataSource.updateTripMeal(tripId, testMeal);

      verify(() => mockApiClient.put('/trips/$tripId/meals/${testMeal.id}', data: any(named: 'data'))).called(1);
    });
  });
}
