import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';

enum MealType {
  breakfast('breakfast', '早餐'),
  lunch('lunch', '午餐'),
  dinner('dinner', '晚餐'),
  snack('snack', '行動糧'),
  other('other', '其他');

  const MealType(this.key, this.label);
  final String key;
  final String label;

  static MealType fromKey(String key) => values.firstWhere((t) => t.key == key, orElse: () => other);
}

/// A meal item together with the trip day it belongs to.
class MealEntry {
  const MealEntry(this.item, this.dayIndex);
  final MealItem item;
  final int dayIndex;

  double get weight => item.weight * item.quantity;
  double get calories => item.calories * item.quantity;
}

double totalMealWeight(Iterable<MealEntry> e) => e.fold(0.0, (s, m) => s + m.weight);
double totalCalories(Iterable<MealEntry> e) => e.fold(0.0, (s, m) => s + m.calories);

String formatKcal(double kcal) => '${kcal.round()} kcal';

List<MealEntry> entriesOfDay(List<MealEntry> all, int dayIndex) => all.where((e) => e.dayIndex == dayIndex).toList();

/// The day's meals in the order of a day (breakfast ... snack), empty types left out.
List<({MealType type, List<MealEntry> entries})> groupMeals(List<MealEntry> dayEntries) {
  final groups = <MealType, List<MealEntry>>{};
  for (final e in dayEntries) {
    groups.putIfAbsent(MealType.fromKey(e.item.mealType), () => []).add(e);
  }
  return [
    for (final t in MealType.values)
      if (groups[t] != null) (type: t, entries: groups[t]!..sort((a, b) => a.item.name.compareTo(b.item.name))),
  ];
}

/// Days shown in the meal plan: D1..Dn of the trip, plus any other day that already has meals.
List<int> mealDayIndexes(Trip trip, List<MealEntry> all) {
  final days = <int>{for (var d = 1; d <= trip.dayCount; d++) d, for (final e in all) e.dayIndex};
  return days.toList()..sort();
}
