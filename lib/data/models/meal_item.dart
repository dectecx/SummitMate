enum MealType {
  preBreakfast('早早餐'),
  breakfast('早餐'),
  lunch('午餐'),
  teatime('下午點心'),
  dinner('晚餐'),
  action('行動糧'),
  emergency('緊急/備用糧');

  final String label;
  const MealType(this.label);
}

class MealItem {
  final String id;
  final String name;
  final double weight; // Grams
  final int calories; // Kcal
  final int quantity;
  final String? note;

  MealItem({
    required this.id,
    required this.name,
    required this.weight,
    required this.calories,
    this.quantity = 1,
    this.note,
  });

  // Create a copy with some changes
  MealItem copyWith({String? name, double? weight, int? calories, int? quantity, String? note}) {
    return MealItem(
      id: id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}

class DailyMealPlan {
  final String day; // D0, D1...
  final Map<MealType, List<MealItem>> meals;

  DailyMealPlan({required this.day, Map<MealType, List<MealItem>>? meals})
    : meals = meals ?? {for (var type in MealType.values) type: []};

  double get totalWeight =>
      meals.values.expand((items) => items).fold(0, (sum, item) => sum + (item.weight * item.quantity));

  int get totalCalories =>
      meals.values.expand((items) => items).fold(0, (sum, item) => sum + (item.calories * item.quantity));
}
