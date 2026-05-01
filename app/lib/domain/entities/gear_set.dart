import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/gear_set_visibility.dart';
import 'gear_item.dart';
import 'daily_meal_plan.dart';

part 'gear_set.freezed.dart';
part 'gear_set.g.dart';

/// 裝備組合實體 (Domain Entity)
@freezed
abstract class GearSet with _$GearSet {
  const GearSet._();

  const factory GearSet({
    required String id,
    required String title,
    required String author,
    @Default(0.0) double totalWeight,
    @Default(0) int itemCount,
    @Default(GearSetVisibility.public) GearSetVisibility visibility,
    required DateTime uploadedAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    List<GearItem>? items,
    List<DailyMealPlan>? meals,
  }) = _GearSet;

  String get formattedWeight {
    if (totalWeight >= 1000) {
      return '${(totalWeight / 1000).toStringAsFixed(1)} kg';
    }
    return '${totalWeight.toStringAsFixed(0)} g';
  }

  String get visibilityIcon {
    switch (visibility) {
      case GearSetVisibility.public:
        return '🌐';
      case GearSetVisibility.protected:
        return '🔒';
      case GearSetVisibility.private:
        return '👤';
    }
  }

  factory GearSet.fromJson(Map<String, dynamic> json) => _$GearSetFromJson(json);
}
