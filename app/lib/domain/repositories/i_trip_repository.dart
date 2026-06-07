import '../../core/error/result.dart';
import '../domain.dart';

/// 行程資料倉庫介面（支援 Offline-First）
///
/// 定義行程資料存取的契約，包含本地快取與雲端同步操作。
abstract interface class ITripRepository {
  /// 初始化 Repository
  Future<Result<void, Exception>> init();

  /// 監聽行程更新事件 (當本地資料變動時觸發)
  Stream<String> get tripUpdateStream;

  // ========== Data Operations ==========

  /// 取得所有行程（本地）
  ///
  /// [userId] 使用者 ID
  Future<Result<List<Trip>, Exception>> getAllTrips(String userId);

  /// 取得當前啟用的行程
  ///
  /// [userId] 使用者 ID
  Future<Result<Trip?, Exception>> getActiveTrip(String userId);

  /// 透過 ID 取得單一行程
  ///
  /// [id] 行程 ID
  Future<Result<Trip?, Exception>> getTripById(String id);

  /// 儲存行程（本地）
  ///
  /// [trip] 行程資料
  Future<Result<void, Exception>> saveTrip(Trip trip);

  /// 更新行程
  ///
  /// [trip] 更新後的行程資料
  Future<Result<void, Exception>> updateTrip(Trip trip);

  /// 刪除行程（本地）
  ///
  /// [id] 行程 ID
  Future<Result<void, Exception>> deleteTrip(String id);

  /// 設定當前啟用的行程（Active Trip）
  ///
  /// [userId] 使用者 ID
  /// [tripId] 行程 ID（null 表示清除）
  Future<Result<void, Exception>> setActiveTrip(String userId, String? tripId);

  // ========== Remote Operations ==========

  // ========== Member Management (Remote) ==========

  /// 取得行程成員列表
  ///
  /// [tripId] 行程 ID
  Future<Result<List<TripMember>, Exception>> getTripMembers(String tripId);

  /// 更新成員角色
  ///
  /// [tripId] 行程 ID / [userId] 使用者 ID / [role] 角色
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role);

  /// 移轉行程所有權
  ///
  /// [tripId] 行程 ID
  /// [targetUserId] 目標使用者 ID
  /// [currentOwnerRole] 當前擁有者退位後的角色
  Future<Result<void, Exception>> transferOwnership(String tripId, String targetUserId, String currentOwnerRole);

  /// 移除成員
  ///
  /// [tripId] 行程 ID / [userId] 使用者 ID
  Future<Result<void, Exception>> removeMember(String tripId, String userId);

  /// 新增成員（透過 Email）
  ///
  /// [tripId] 行程 ID / [email] 使用者 Email / [role] 角色（預設 member）
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'});

  /// 新增成員（透過 ID）
  ///
  /// [tripId] 行程 ID / [userId] 使用者 ID / [role] 角色（預設 member）
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'});

  /// 搜尋使用者（透過 Email）
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email);

  /// 搜尋使用者（透過 ID）
  Future<Result<UserProfile, Exception>> searchUserById(String userId);

  // ========== Meal Plan Day Operations ==========

  /// 取得行程的糧食計畫天數列表
  Future<Result<List<MealPlanDay>, Exception>> getMealPlanDays(String tripId);

  /// 新增糧食計畫天數
  Future<Result<MealPlanDay, Exception>> addMealPlanDay(String tripId, String name, {String? linkedItineraryDay});

  /// 更新糧食計畫天數
  Future<Result<MealPlanDay, Exception>> updateMealPlanDay(
    String tripId,
    String dayId,
    String name, {
    String? linkedItineraryDay,
  });

  /// 刪除糧食計畫天數
  Future<Result<void, Exception>> deleteMealPlanDay(String tripId, String dayId);

  /// 更新本地行程 ID (遷移行程及其所有關聯資料)
  Future<Result<void, Exception>> updateLocalTripId(String oldId, String newId);

  /// 將行程標記為待更新狀態 (當關聯資料如裝備、行程節點變動時)
  Future<Result<void, Exception>> markTripAsPendingUpdate(String tripId);
}
