import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../data/models/meal_item.dart';

class MealCubit extends Cubit<MealState> {
  MealCubit() : super(const MealInitial()) {
    reset();
  }

  /// 初始化或重置
  void reset() {
    emit(
      MealLoaded(
        dailyPlans: [
          DailyMealPlan(day: 'D0'),
          DailyMealPlan(day: 'D1'),
          DailyMealPlan(day: 'D2'),
        ],
      ),
    );
  }

  /// 新增餐點項目
  void addMealItem(String day, MealType type, String name, double weight, double calories) {
    if (state is! MealLoaded) return;

    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final newItem = MealItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        weight: weight,
        calories: calories,
      );

      // Clone existing map
      final plan = currentPlans[planIndex];
      // Note: This relies on MealItem/DailyMealPlan mutability in current Provider logic.
      // If we strictly follow BLoC, we should deep copy.
      // For migration simplicity, we use the mutable approach wrapped in new list emittance.
      
      if (plan.meals[type] == null) {
        plan.meals[type] = [];
      }
      plan.meals[type]!.add(newItem);

      // Force emit with new list reference
      emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
    }
  }

  /// 移除餐點項目
  void removeMealItem(String day, MealType type, String itemId) {
    if (state is! MealLoaded) return;
    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      currentPlans[planIndex].meals[type]?.removeWhere((item) => item.id == itemId);
      emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
    }
  }

  /// 更新餐點數量
  void updateMealItemQuantity(String day, MealType type, String itemId, int quantity) {
    if (state is! MealLoaded) return;
    if (quantity < 1) quantity = 1;

    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final items = currentPlans[planIndex].meals[type];
      if (items != null) {
        final itemIndex = items.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          items[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
          emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
        }
      }
    }
  }

  /// 設定計畫 (例如匯入)
  void setDailyPlans(List<DailyMealPlan> newPlans) {
    emit(MealLoaded(dailyPlans: newPlans));
  }
}
