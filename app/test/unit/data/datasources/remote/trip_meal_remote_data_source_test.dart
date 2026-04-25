import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/trip_meal_api_models.dart';
import 'package:summitmate/data/api/services/trip_meal_api_service.dart';
import 'package:summitmate/data/datasources/remote/trip_meal_remote_data_source.dart';
import 'package:summitmate/data/models/meal_item.dart';

class MockTripMealApiService extends Mock implements TripMealApiService {}

class FakeTripMealItemRequest extends Fake implements TripMealItemRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripMealItemRequest());
  });

  late TripMealRemoteDataSource dataSource;
  late MockTripMealApiService mockApiService;

  setUp(() {
    mockApiService = MockTripMealApiService();
    dataSource = TripMealRemoteDataSource.testable(mockApiService);
  });

  final testResponse = TripMealItemResponse(
    id: 'meal-1',
    tripId: 'trip-1',
    day: 'D1',
    mealType: 'breakfast',
    name: 'Rice',
    weight: 500,
    calories: 500,
    quantity: 1,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final testMeal = MealItem(id: 'meal-1', name: 'Rice', weight: 500, calories: 500);

  group('TripMealRemoteDataSource.getTripMeals', () {
    test('returns list of meal items on success', () async {
      when(() => mockApiService.listMeals('trip-1')).thenAnswer((_) async => [testResponse]);

      final result = await dataSource.getTripMeals('trip-1');

      expect(result.length, 1);
      expect(result[0].name, 'Rice');
      verify(() => mockApiService.listMeals('trip-1')).called(1);
    });

    test('rethrows exception on failure', () async {
      when(() => mockApiService.listMeals(any())).thenThrow(Exception('Network error'));

      expect(() => dataSource.getTripMeals('trip-1'), throwsException);
    });
  });

  group('TripMealRemoteDataSource CRUD', () {
    test('addTripMeal calls api and returns mapped item', () async {
      when(
        () => mockApiService.addMeal('trip-1', any()),
      ).thenAnswer((_) async => testResponse);

      final result = await dataSource.addTripMeal(
        'trip-1',
        testMeal,
        day: 'D1',
        mealType: 'breakfast',
      );

      expect(result.name, 'Rice');
      verify(() => mockApiService.addMeal('trip-1', any())).called(1);
    });

    test('updateTripMeal calls api and returns mapped item', () async {
      when(
        () => mockApiService.updateMeal('trip-1', 'meal-1', any()),
      ).thenAnswer((_) async => testResponse);

      final result = await dataSource.updateTripMeal(
        'trip-1',
        testMeal,
        day: 'D1',
        mealType: 'breakfast',
      );

      expect(result.name, 'Rice');
      verify(() => mockApiService.updateMeal('trip-1', 'meal-1', any())).called(1);
    });

    test('deleteTripMeal calls api', () async {
      when(() => mockApiService.deleteMeal('trip-1', 'meal-1')).thenAnswer((_) async {});

      await dataSource.deleteTripMeal('trip-1', 'meal-1');

      verify(() => mockApiService.deleteMeal('trip-1', 'meal-1')).called(1);
    });

    test('replaceAllTripMeals calls api with mapped requests', () async {
      when(() => mockApiService.replaceAllMeals('trip-1', any())).thenAnswer((_) async {});

      await dataSource.replaceAllTripMeals('trip-1', [
        (item: testMeal, day: 'D1', mealType: 'breakfast'),
      ]);

      verify(() => mockApiService.replaceAllMeals('trip-1', any())).called(1);
    });
  });
}
