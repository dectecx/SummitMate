import '../../models/meal_item.dart';
import '../models/trip_meal_api_models.dart';

/// TripMealItem API Model ↔ Domain Model 轉換
///
/// 注意：API 的 TripMealItem 包含 trip_id、day、meal_type 等行程脈絡欄位，
/// 而 domain MealItem 僅保存餐點本身資訊（不含行程上下文）。
/// Mapper 負責在兩者之間進行轉換。
class TripMealApiMapper {
  /// TripMealItemResponse → MealItem (domain model)
  ///
  /// [response] API 回應的餐點資料
  static MealItem fromResponse(TripMealItemResponse response) {
    return MealItem(
      id: response.id,
      name: response.name,
      weight: response.weight,
      calories: response.calories,
      quantity: response.quantity,
      note: response.note,
    );
  }

  /// MealItem (domain model) + 行程脈絡 → TripMealItemRequest
  ///
  /// [item] 餐點 domain model
  /// [day] 天次，例如 "D1"、"D2"
  /// [mealType] 餐食類型，例如 "breakfast"、"lunch"
  static TripMealItemRequest toRequest(
    MealItem item, {
    required String day,
    required String mealType,
  }) {
    return TripMealItemRequest(
      day: day,
      mealType: mealType,
      name: item.name,
      weight: item.weight,
      calories: item.calories,
      quantity: item.quantity,
      note: item.note,
    );
  }
}
