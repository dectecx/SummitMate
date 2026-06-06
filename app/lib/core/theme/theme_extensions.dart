import 'package:flutter/material.dart';
import '../../domain/enums/meal_type.dart';
import '../constants.dart';

@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  final Color preBreakfast;
  final Color breakfast;
  final Color lunch;
  final Color teatime;
  final Color dinner;
  final Color action;
  final Color emergency;

  final Color sleep;
  final Color cook;
  final Color wear;
  final Color other;

  const CategoryColors({
    required this.preBreakfast,
    required this.breakfast,
    required this.lunch,
    required this.teatime,
    required this.dinner,
    required this.action,
    required this.emergency,
    required this.sleep,
    required this.cook,
    required this.wear,
    required this.other,
  });

  Color getMealColor(MealType type) {
    switch (type) {
      case MealType.preBreakfast:
        return preBreakfast;
      case MealType.breakfast:
        return breakfast;
      case MealType.lunch:
        return lunch;
      case MealType.teatime:
        return teatime;
      case MealType.dinner:
        return dinner;
      case MealType.action:
        return action;
      case MealType.emergency:
        return emergency;
    }
  }

  Color getGearColor(String category) {
    switch (category) {
      case GearCategory.sleep:
        return sleep;
      case GearCategory.cook:
        return cook;
      case GearCategory.wear:
        return wear;
      case GearCategory.other:
      default:
        return other;
    }
  }

  @override
  CategoryColors copyWith({
    Color? preBreakfast,
    Color? breakfast,
    Color? lunch,
    Color? teatime,
    Color? dinner,
    Color? action,
    Color? emergency,
    Color? sleep,
    Color? cook,
    Color? wear,
    Color? other,
  }) {
    return CategoryColors(
      preBreakfast: preBreakfast ?? this.preBreakfast,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      teatime: teatime ?? this.teatime,
      dinner: dinner ?? this.dinner,
      action: action ?? this.action,
      emergency: emergency ?? this.emergency,
      sleep: sleep ?? this.sleep,
      cook: cook ?? this.cook,
      wear: wear ?? this.wear,
      other: other ?? this.other,
    );
  }

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    if (other is! CategoryColors) return this;
    return CategoryColors(
      preBreakfast: Color.lerp(preBreakfast, other.preBreakfast, t)!,
      breakfast: Color.lerp(breakfast, other.breakfast, t)!,
      lunch: Color.lerp(lunch, other.lunch, t)!,
      teatime: Color.lerp(teatime, other.teatime, t)!,
      dinner: Color.lerp(dinner, other.dinner, t)!,
      action: Color.lerp(action, other.action, t)!,
      emergency: Color.lerp(emergency, other.emergency, t)!,
      sleep: Color.lerp(sleep, other.sleep, t)!,
      cook: Color.lerp(cook, other.cook, t)!,
      wear: Color.lerp(wear, other.wear, t)!,
      other: Color.lerp(this.other, other.other, t)!,
    );
  }
}
