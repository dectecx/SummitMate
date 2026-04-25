import '../../models/meal_item.dart';

/// 行程餐飲 (Trip Meal) 的遠端資料來源介面
abstract interface class ITripMealRemoteDataSource {
  /// 取得行程所有餐點
  ///
  /// [tripId] 行程 ID
  Future<List<MealItem>> getTripMeals(String tripId);

  /// 新增餐點至行程
  ///
  /// [tripId] 行程 ID
  /// [item] 餐點資料
  /// [day] 天次，例如 "D1"、"D2"
  /// [mealType] 餐食類型，例如 "breakfast"、"lunch"
  Future<MealItem> addTripMeal(String tripId, MealItem item, {required String day, required String mealType});

  /// 更新行程餐點內容
  ///
  /// [tripId] 行程 ID
  /// [item] 欲更新的餐點（需含 id）
  /// [day] 天次
  /// [mealType] 餐食類型
  Future<MealItem> updateTripMeal(String tripId, MealItem item, {required String day, required String mealType});

  /// 從行程中刪除餐點
  ///
  /// [tripId] 行程 ID
  /// [itemId] 餐點 ID
  Future<void> deleteTripMeal(String tripId, String itemId);

  /// 批量替換行程所有餐點（離線同步用）
  ///
  /// [tripId] 行程 ID
  /// [requests] 完整餐點清單（含 day/mealType 上下文）
  Future<void> replaceAllTripMeals(String tripId, List<({MealItem item, String day, String mealType})> requests);
}
