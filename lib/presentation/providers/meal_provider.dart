import 'package:flutter/material.dart';
import '../../data/models/meal_item.dart';

class MealProvider extends ChangeNotifier {
  final List<DailyMealPlan> _dailyPlans = [
    DailyMealPlan(day: 'D0'),
    DailyMealPlan(day: 'D1'),
    DailyMealPlan(day: 'D2'),
  ];

  List<DailyMealPlan> get dailyPlans => _dailyPlans;

  // 取得總重量 (所有天數)
  double get totalWeightKg {
    double totalGrams = 0;
    for (var plan in _dailyPlans) {
      totalGrams += plan.totalWeight;
    }
    return totalGrams / 1000.0;
  }

  // 新增餐點
  void addMealItem(String day, MealType type, String name, double weight, double calories) {
    final planIndex = _dailyPlans.indexWhere((p) => p.day == day);
    if (planIndex == -1) return;

    final newItem = MealItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      weight: weight,
      calories: calories,
    );

    _dailyPlans[planIndex].meals[type]?.add(newItem);
    notifyListeners();
  }

  // 刪除餐點
  void removeMealItem(String day, MealType type, String itemId) {
    final planIndex = _dailyPlans.indexWhere((p) => p.day == day);
    if (planIndex == -1) return;

    _dailyPlans[planIndex].meals[type]?.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // 更新餐點數量
  void updateMealItemQuantity(String day, MealType type, String itemId, int quantity) {
    if (quantity < 1) quantity = 1;
    final planIndex = _dailyPlans.indexWhere((p) => p.day == day);
    if (planIndex == -1) return;

    final items = _dailyPlans[planIndex].meals[type];
    if (items == null) return;

    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    items[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
    notifyListeners();
  }
}
