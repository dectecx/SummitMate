import '../../../domain/entities/trip.dart';
import '../../../domain/entities/meal_plan_day.dart';

/// 行程 (Trip) 的本地資料來源介面
///
/// 負責定義對本地行程資料庫 (如 Drift) 的 CRUD 操作，以及管理當前活動行程。
abstract interface class ITripLocalDataSource {
  /// 初始化資料來源
  /// 取得所有行程列表
  Future<List<Trip>> getAllTrips();

  /// 透過 ID 取得單一行程
  ///
  /// [id] 行程 ID
  Future<Trip?> getTripById(String id);

  /// 新增行程
  ///
  /// [trip] 欲新增的行程物件
  Future<void> addTrip(Trip trip);

  /// 更新行程
  ///
  /// [trip] 更新後的行程物件
  Future<void> updateTrip(Trip trip);

  /// 刪除行程
  ///
  /// [id] 欲刪除的行程 ID
  Future<void> deleteTrip(String id);

  /// 設定當前活動行程 (Active TripModel)
  ///
  /// [userId] 使用者 ID
  /// [tripId] 要設為 Active 的行程 ID
  Future<void> setActiveTrip(String userId, String tripId);

  /// 取得當前活動行程
  ///
  /// [userId] 使用者 ID
  Future<Trip?> getActiveTrip(String userId);

  /// 清除所有行程 (登出時使用)
  Future<void> clear();

  // ========== Meal Plan Day Operations ==========

  /// 取得行程的所有糧食計畫天數
  Future<List<MealPlanDay>> getMealPlanDays(String tripId);

  /// 新增或更新糧食計畫天數
  Future<void> saveMealPlanDay(MealPlanDay day, String tripId);

  /// 刪除糧食計畫天數
  Future<void> deleteMealPlanDay(String dayId);

  /// 批量更新糧食計畫天數 (通常用於從雲端同步下來時，完整替換或更新)
  Future<void> replaceMealPlanDays(String tripId, List<MealPlanDay> days);

  /// 遷移行程 ID (用於離線建立行程後，上傳至雲端取得新 ID 時，同步更新所有本地關聯資料)
  Future<void> migrateTripId(String oldId, String newId);

  /// 將行程標記為待更新
  Future<void> markTripAsPendingUpdate(String tripId);
}
