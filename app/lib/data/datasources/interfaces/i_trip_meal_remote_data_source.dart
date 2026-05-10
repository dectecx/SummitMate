import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/domain/entities/meal_plan_day.dart';

/// 行程餐飲 (Trip Meal) 的遠端資料來源介面
abstract interface class ITripMealRemoteDataSource {
  // ========== Meal Plan Day Management ==========

  /// 取得行程的所有糧食計畫天數
  Future<List<MealPlanDay>> getMealPlanDays(String tripId);

  /// 新增糧食計畫天數
  Future<MealPlanDay> addMealPlanDay(String tripId, String name, {String? linkedItineraryDay});

  /// 更新糧食計畫天數
  Future<MealPlanDay> updateMealPlanDay(String tripId, String dayId, String name, {String? linkedItineraryDay});

  /// 刪除糧食計畫天數
  Future<void> deleteMealPlanDay(String tripId, String dayId);

  // ========== Meal Item Operations ==========

  /// 取得行程所有餐點
  Future<List<MealItem>> getTripMeals(String tripId);

  /// 新增餐點
  Future<MealItem> addTripMeal(String tripId, MealItem item, {required String mealPlanDayId, required String mealType});

  /// 更新餐點
  Future<MealItem> updateTripMeal(
    String tripId,
    MealItem item, {
    required String mealPlanDayId,
    required String mealType,
  });

  /// 刪除餐點
  Future<void> deleteTripMeal(String tripId, String itemId);
}
