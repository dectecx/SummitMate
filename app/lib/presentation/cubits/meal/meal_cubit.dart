import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../data/models/meal_item.dart';

class MealCubit extends Cubit<MealState> {
  MealCubit()
    : super(
        MealLoaded(
          dailyPlans: [
            DailyMealPlan(day: 'D0'),
            DailyMealPlan(day: 'D1'),
            DailyMealPlan(day: 'D2'),
          ],
        ),
      );

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
  ///
  /// [day] 天數 (e.g., "D1")
  /// [type] 餐別 (早餐/午餐/晚餐/行動糧)
  /// [name] 餐點名稱
  /// [weight] 重量 (g)
  /// [calories] 熱量 (kcal)
  void addMealItem(String day, MealType type, String name, double weight, double calories) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newItem = MealItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        weight: weight,
        calories: calories,
      );

      // Deep copy meals map and list
      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      itemList.add(newItem);
      newMeals[type] = itemList;

      currentPlans[planIndex] = DailyMealPlan(day: day, meals: newMeals);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 移除餐點項目
  ///
  /// [day] 天數
  /// [type] 餐別
  /// [itemId] 項目 ID
  void removeMealItem(String day, MealType type, String itemId) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      itemList.removeWhere((item) => item.id == itemId);
      newMeals[type] = itemList;

      currentPlans[planIndex] = DailyMealPlan(day: day, meals: newMeals);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 更新餐點數量
  ///
  /// [day] 天數
  /// [type] 餐別
  /// [itemId] 項目 ID
  /// [quantity] 新數量
  void updateMealItemQuantity(String day, MealType type, String itemId, int quantity) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;
    if (quantity < 1) quantity = 1;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      final itemIndex = itemList.indexWhere((item) => item.id == itemId);

      if (itemIndex != -1) {
        itemList[itemIndex] = itemList[itemIndex].copyWith(quantity: quantity);
        newMeals[type] = itemList;
        currentPlans[planIndex] = DailyMealPlan(day: day, meals: newMeals);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      }
    }
  }

  /// 設定計畫 (例如匯入)
  ///
  /// [newPlans] 新的每日計畫列表
  void setDailyPlans(List<DailyMealPlan> newPlans) {
    emit(MealLoaded(dailyPlans: newPlans));
  }
}
