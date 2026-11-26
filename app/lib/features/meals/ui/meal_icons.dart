import 'package:material_ui/material_ui.dart';

import '../domain/meal_logic.dart';

IconData mealIcon(MealType type) => switch (type) {
  MealType.breakfast => Icons.wb_twilight_outlined,
  MealType.lunch => Icons.restaurant_outlined,
  MealType.dinner => Icons.nightlight_outlined,
  MealType.snack => Icons.cookie_outlined,
  MealType.other => Icons.category_outlined,
};
