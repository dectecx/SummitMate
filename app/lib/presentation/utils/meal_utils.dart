import 'package:flutter/material.dart';
import '../../domain/enums/meal_type.dart';
import '../../core/theme/theme_extensions.dart';

/// 糧食相關的 UI 工具類
class MealUIUtils {
  /// 取得餐別對應的圖示
  static IconData getMealIcon(MealType type) {
    switch (type) {
      case MealType.preBreakfast:
        return Icons.wb_twilight;
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.teatime:
        return Icons.coffee;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.action:
        return Icons.directions_walk;
      case MealType.emergency:
        return Icons.medical_services;
    }
  }

  /// 取得餐別對應的顏色
  static Color getMealColor(MealType type, BuildContext context) {
    final categoryColors = Theme.of(context).extension<CategoryColors>();
    if (categoryColors != null) {
      return categoryColors.getMealColor(type);
    }
    switch (type) {
      case MealType.preBreakfast:
        return Colors.indigo;
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.teatime:
        return Colors.brown;
      case MealType.dinner:
        return Colors.deepPurple;
      case MealType.action:
        return Colors.blue;
      case MealType.emergency:
        return Colors.red;
    }
  }
}
