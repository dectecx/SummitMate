import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_plan_day.freezed.dart';
part 'meal_plan_day.g.dart';

/// 糧食計畫天數實體 (Domain Entity)
@freezed
abstract class MealPlanDay with _$MealPlanDay {
  const factory MealPlanDay({
    required String id,
    required String name,
    String? linkedItineraryDay, // nil 表示未綁定行程
  }) = _MealPlanDay;

  factory MealPlanDay.fromJson(Map<String, dynamic> json) => _$MealPlanDayFromJson(json);
}
