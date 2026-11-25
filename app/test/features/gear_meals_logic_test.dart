import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/gear/domain/gear_logic.dart';
import 'package:summitmate/features/meals/domain/meal_logic.dart';

GearItem gear(String id, {String name = '', double w = 0, String cat = 'other', int qty = 1, bool packed = false, int order = 0}) =>
    GearItem(id: id, tripId: 't', name: name.isEmpty ? id : name, weight: w, category: cat, quantity: qty, isChecked: packed, sortOrder: order);

MealEntry meal(String id, int day, {String type = 'lunch', double w = 0, double kcal = 0, int qty = 1, String? name, int order = 0}) => MealEntry(
  MealItem(id: id, tripId: 't', mealPlanDayId: 'd$day', mealType: type, name: name ?? id, weight: w, calories: kcal, quantity: qty, note: '', sortOrder: order),
  day,
);

void main() {
  group('gear', () {
    test('weights are shown in grams below a kilogram and kilograms above', () {
      expect(formatWeight(0), '0 g');
      expect(formatWeight(850), '850 g');
      expect(formatWeight(12.5), '12.5 g');
      expect(formatWeight(1000), '1.00 kg');
      expect(formatWeight(4853), '4.85 kg');
    });

    test('totals count quantity; packed totals only count ticked items', () {
      final items = [gear('a', w: 900, packed: true), gear('b', w: 380, qty: 2), gear('c', w: 100, packed: true)];
      expect(totalWeight(items), 1760);
      expect(packedWeight(items), 1000);
      expect(packedCount(items), 2);
      expect(totalWeight(const []), 0);
    });

    test('groups follow the category order and items keep the order they were added in', () {
      final groups = groupGear([
        gear('x', cat: 'other', order: 0),
        gear('late', cat: 'sleep', order: 5),
        gear('early', cat: 'sleep', order: 1),
        gear('pot', cat: 'cook', order: 2),
        gear('mystery', cat: 'from-a-newer-version', order: 3),
      ]);
      expect(groups.map((g) => g.category), [GearCategory.sleep, GearCategory.cook, GearCategory.other]);
      expect(groups[0].items.map((i) => i.id), ['early', 'late']);
      expect(groups[2].items.map((i) => i.id), ['x', 'mystery'], reason: 'unknown categories fall back to other');
      expect(groupGear(const []), isEmpty);
    });
  });

  group('meals', () {
    test('totals multiply by servings', () {
      final e = [meal('a', 1, w: 180, kcal: 320, qty: 2), meal('b', 1, w: 120, kcal: 450)];
      expect(totalMealWeight(e), 480);
      expect(totalCalories(e), 1090);
      expect(formatKcal(1090.4), '1090 kcal');
    });

    test('a day is split by meal type in the order of the day', () {
      final day = entriesOfDay([meal('s', 1, type: 'snack'), meal('d', 1, type: 'dinner'), meal('b', 1, type: 'breakfast'), meal('other-day', 2)], 1);
      expect(day.length, 3);
      final groups = groupMeals(day);
      expect(groups.map((g) => g.type), [MealType.breakfast, MealType.dinner, MealType.snack]);
      expect(MealType.fromKey('nonsense'), MealType.other);
    });

    test('day chips cover the trip plus any day that already has meals', () {
      final trip = Trip(id: 't', ownerId: null, name: 'x', description: '', startDate: '2026-05-01', endDate: '2026-05-03', coverImage: null, isSample: false);
      expect(mealDayIndexes(trip, const []), [1, 2, 3]);
      expect(mealDayIndexes(trip, [meal('a', 5), meal('b', 0)]), [0, 1, 2, 3, 5]);
    });
  });
}
