import 'package:json_annotation/json_annotation.dart';
import '../../domain/enums/meal_type.dart';
import '../../domain/entities/daily_meal_plan.dart';
import 'meal_item_model.dart';

part 'daily_meal_plan_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyMealPlanModel {
  final String day;

  @JsonKey(fromJson: _mealsFromJson, toJson: _mealsToJson)
  final Map<MealType, List<MealItemModel>> meals;

  DailyMealPlanModel({required this.day, Map<MealType, List<MealItemModel>>? meals})
    : meals = meals ?? {for (var type in MealType.values) type: []};

  DailyMealPlan toDomain() =>
      DailyMealPlan(day: day, meals: meals.map((key, value) => MapEntry(key, value.map((m) => m.toDomain()).toList())));

  factory DailyMealPlanModel.fromDomain(DailyMealPlan entity) => DailyMealPlanModel(
    day: entity.day,
    meals: entity.meals.map((key, value) => MapEntry(key, value.map((e) => MealItemModel.fromDomain(e)).toList())),
  );

  factory DailyMealPlanModel.fromJson(Map<String, dynamic> json) => _$DailyMealPlanModelFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMealPlanModelToJson(this);

  static Map<MealType, List<MealItemModel>> _mealsFromJson(Map<String, dynamic>? json) {
    if (json == null) return {for (var type in MealType.values) type: []};
    final Map<MealType, List<MealItemModel>> result = {};
    for (var type in MealType.values) {
      final itemsJson = json[type.name] as List<dynamic>? ?? [];
      result[type] = itemsJson.map((e) => MealItemModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return result;
  }

  static Map<String, dynamic> _mealsToJson(Map<MealType, List<MealItemModel>> meals) {
    return meals.map((type, items) => MapEntry(type.name, items.map((e) => e.toJson()).toList()));
  }
}
