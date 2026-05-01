import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/meal_type.dart';
import 'meal_item.dart';

part 'daily_meal_plan.freezed.dart';
part 'daily_meal_plan.g.dart';

/// 每日餐食計畫實體 (Domain Entity)
@freezed
abstract class DailyMealPlan with _$DailyMealPlan {
  const DailyMealPlan._();

  const factory DailyMealPlan({
    required String day,
    @Default({}) Map<MealType, List<MealItem>> meals,
  }) = _DailyMealPlan;

  double get totalWeight =>
      meals.values.expand((items) => items).fold(0.0, (sum, item) => sum + (item.weight * item.quantity));

  double get totalCalories =>
      meals.values.expand((items) => items).fold(0.0, (sum, item) => sum + (item.calories * item.quantity));

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) => _$DailyMealPlanFromJson(json);
}
