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
  final double calories; // Kcal
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
  MealItem copyWith({String? name, double? weight, double? calories, int? quantity, String? note}) {
    return MealItem(
      id: id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'weight': weight, 'calories': calories, 'quantity': quantity, 'note': note};
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String?,
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

  double get totalCalories =>
      meals.values.expand((items) => items).fold(0, (sum, item) => sum + (item.calories * item.quantity));

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'meals': meals.map((type, items) => MapEntry(type.name, items.map((e) => e.toJson()).toList())),
    };
  }

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as String;
    final mealsJson = json['meals'] as Map<String, dynamic>? ?? {};

    final Map<MealType, List<MealItem>> parsedMeals = {};
    for (var type in MealType.values) {
      final itemsJson = mealsJson[type.name] as List<dynamic>? ?? [];
      parsedMeals[type] = itemsJson.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return DailyMealPlan(day: day, meals: parsedMeals);
  }
}
