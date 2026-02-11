import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal_item.g.dart';

/// 餐食類型 (早/午/晚/行動糧...)
enum MealType {
  /// 早早餐 (攻頂前)
  @JsonValue('pre_breakfast')
  preBreakfast,

  /// 早餐
  @JsonValue('breakfast')
  breakfast,

  /// 午餐
  @JsonValue('lunch')
  lunch,

  /// 下午點心
  @JsonValue('teatime')
  teatime,

  /// 晚餐
  @JsonValue('dinner')
  dinner,

  /// 行動糧
  @JsonValue('action')
  action,

  /// 緊急/備用糧
  @JsonValue('emergency')
  emergency;

  String get label {
    switch (this) {
      case MealType.preBreakfast:
        return '早早餐';
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.teatime:
        return '下午點心';
      case MealType.dinner:
        return '晚餐';
      case MealType.action:
        return '行動糧';
      case MealType.emergency:
        return '緊急/備用糧';
    }
  }
}

/// 餐食項目
@JsonSerializable(fieldRename: FieldRename.snake)
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
  @JsonKey(defaultValue: 1)
  final int quantity;

  /// 備註
  final String? note;

  const MealItem({
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

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
  Map<String, dynamic> toJson() => _$MealItemToJson(this);

  @override
  List<Object?> get props => [id, name, weight, calories, quantity, note];
}

/// 每日餐食計畫
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyMealPlan extends Equatable {
  /// 天數 (Days), e.g. "D0", "D1"
  final String day;

  /// 餐食 map: `MealType` -> `List<MealItem>`
  /// Note: 使用自定義轉換，因為 `Map<Enum, List>` 需要特殊處理
  @JsonKey(fromJson: _mealsFromJson, toJson: _mealsToJson)
  final Map<MealType, List<MealItem>> meals;

  DailyMealPlan({required this.day, Map<MealType, List<MealItem>>? meals})
    : meals = meals ?? {for (var type in MealType.values) type: []};

  double get totalWeight =>
      meals.values.expand((items) => items).fold(0, (sum, item) => sum + (item.weight * item.quantity));

  double get totalCalories =>
      meals.values.expand((items) => items).fold(0, (sum, item) => sum + (item.calories * item.quantity));

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) => _$DailyMealPlanFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMealPlanToJson(this);

  @override
  List<Object?> get props => [day, meals];

  @override
  bool? get stringify => true;

  // Custom converters for meals map
  static Map<MealType, List<MealItem>> _mealsFromJson(Map<String, dynamic>? json) {
    if (json == null) return {for (var type in MealType.values) type: []};

    final Map<MealType, List<MealItem>> result = {};
    for (var type in MealType.values) {
      final itemsJson = json[type.name] as List<dynamic>? ?? [];
      result[type] = itemsJson.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return result;
  }

  static Map<String, dynamic> _mealsToJson(Map<MealType, List<MealItem>> meals) {
    return meals.map((type, items) => MapEntry(type.name, items.map((e) => e.toJson()).toList()));
  }
}
