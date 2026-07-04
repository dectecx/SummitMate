/// 行程天數操作的特定例外類型
library;

/// 糧食計畫天數綁定例外
///
/// 當嘗試刪除一個已綁定糧食計畫天數的行程天數，
/// 且未設定 `confirmUnlink` 時拋出此例外。
/// Cubit 層接收後應 emit [ItineraryDayRemovalWarning] 要求使用者確認。
class MealPlanDayLinkedToItineraryException implements Exception {
  final String dayName;
  final String mealPlanDayId;

  const MealPlanDayLinkedToItineraryException({
    required this.dayName,
    required this.mealPlanDayId,
  });

  @override
  String toString() =>
      'MealPlanDayLinkedToItineraryException: day "$dayName" is linked to meal plan day $mealPlanDayId';
}
