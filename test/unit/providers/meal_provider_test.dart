
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/meal_item.dart';
import 'package:summitmate/presentation/providers/meal_provider.dart';

void main() {
  late MealProvider provider;

  setUp(() {
    provider = MealProvider();
  });

  group('MealProvider Tests', () {
    test('initial state should have D0, D1, D2', () {
      expect(provider.dailyPlans.length, 3);
      expect(provider.dailyPlans[0].day, 'D0');
      expect(provider.totalWeightKg, 0);
    });

    test('addMealItem should add item and update total weight', () {
      // Add 100g item to D1 Lunch
      provider.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);

      expect(provider.dailyPlans[1].meals[MealType.lunch]?.length, 1);
      final item = provider.dailyPlans[1].meals[MealType.lunch]?.first;
      expect(item?.name, 'Rice');

      // Total weight should be 0.1 kg
      expect(provider.totalWeightKg, 0.1);
    });

    test('addMealItem across multiple days should accumulate weight', () {
      // D1: 100g
      provider.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);
      // D2: 200g
      provider.addMealItem('D2', MealType.dinner, 'Steak', 200, 500);

      expect(provider.totalWeightKg, 0.3); // 300g = 0.3kg
    });

    test('removeMealItem should remove item and update weight', () {
      provider.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);
      final item = provider.dailyPlans[1].meals[MealType.lunch]?.first;

      provider.removeMealItem('D1', MealType.lunch, item!.id);

      expect(provider.dailyPlans[1].meals[MealType.lunch]?.isEmpty, true);
      expect(provider.totalWeightKg, 0);
    });

    test('addMealItem should ignore invalid day', () {
      provider.addMealItem('D99', MealType.lunch, 'Magic', 100, 100);
      expect(provider.totalWeightKg, 0);
    });
  });
}
