import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';

/// 餐食類型 (早/午/晚/行動糧...)
enum MealType {
  /// 早早餐 (攻頂前)
  preBreakfast('早早餐'),

  /// 早餐
  breakfast('早餐'),

  /// 午餐
  lunch('午餐'),

  /// 下午點心
  teatime('下午點心'),

  /// 晚餐
  dinner('晚餐'),

  /// 行動糧
  action('行動糧'),

  /// 緊急/備用糧
  emergency('緊急/備用糧');

  final String label;
  const MealType(this.label);
}

/// 餐食項目
class MealItem extends Equatable {
  /// 唯一識別碼
  final String id;

  /// 食物名稱
  final String name;

  /// 重量 (公克)
  final double weight;

  /// 熱量 (Kcal)
  final double calories;

  /// 數量
  final int quantity;

  /// 備註
  final String? note;

  MealItem({
    required this.id,
    required this.name,
    required this.weight,
    required this.calories,
    this.quantity = 1,
    this.note,
  });

  /// 建立副本並更新欄位
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

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'weight': weight, 'calories': calories, 'quantity': quantity, 'note': note};
  }

  /// 從 JSON 建立
  factory MealItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw ArgumentError('MealItem ID is required');
    if (json['name'] == null) throw ArgumentError('MealItem name is required');

    return MealItem(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, weight, calories, quantity, note];
}

/// 每日餐食計畫
class DailyMealPlan extends Equatable {
  /// 天數 (Days), e.g. "D0", "D1"
  final String day;

  /// 餐食 map: MealType -> List<MealItem>
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

  @override
  List<Object?> get props => [day, meals];

  @override
  bool? get stringify => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is DailyMealPlan &&
          day == other.day &&
          const MapEquality(values: ListEquality()).equals(meals, other.meals);

  @override
  int get hashCode => day.hashCode ^ const MapEquality(values: ListEquality()).hash(meals);
}
