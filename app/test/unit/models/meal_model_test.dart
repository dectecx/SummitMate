import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/meal_item.dart';

void main() {
  group('MealItem Tests', () {
    test('should create MealItem correctly', () {
      final item = MealItem(id: '1', name: 'Rice', weight: 100, calories: 350);

      expect(item.id, '1');
      expect(item.name, 'Rice');
      expect(item.weight, 100);
      expect(item.calories, 350);
      expect(item.quantity, 1);
    });

    test('should copyWith correctly', () {
      final item = MealItem(id: '1', name: 'Rice', weight: 100, calories: 350);

      final copy = item.copyWith(quantity: 2, name: 'Big Rice');

      expect(copy.id, '1');
      expect(copy.name, 'Big Rice');
      expect(copy.weight, 100);
      expect(copy.quantity, 2);
    });
  });

  group('DailyMealPlan Tests', () {
    test('should calculate total weight and calories correctly', () {
      final item1 = MealItem(
        id: '1',
        name: 'Rice',
        weight: 100,
        calories: 350,
        quantity: 2, // 200g, 700kcal
      );

      final item2 = MealItem(
        id: '2',
        name: 'Soup',
        weight: 50,
        calories: 100,
        quantity: 1, // 50g, 100kcal
      );

      final plan = DailyMealPlan(
        day: 'D1',
        meals: {
          MealType.breakfast: [item1],
          MealType.dinner: [item2],
        },
      );

      expect(plan.totalWeight, 250); // 200 + 50
      expect(plan.totalCalories, 800); // 700 + 100
    });

    test('should return 0 for empty plan', () {
      final plan = DailyMealPlan(day: 'D1');
      expect(plan.totalWeight, 0);
      expect(plan.totalCalories, 0);
    });
  });
}
