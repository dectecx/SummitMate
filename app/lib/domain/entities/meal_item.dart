import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_item.freezed.dart';
part 'meal_item.g.dart';

/// 餐食項目實體 (Domain Entity)
@freezed
abstract class MealItem with _$MealItem {
  const factory MealItem({
    required String id,
    required String name,
    required double weight,
    required double calories,
    @Default(1) int quantity,
    String? note,
  }) = _MealItem;

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
}
