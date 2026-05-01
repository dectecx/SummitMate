import '../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../domain.dart';

/// 行程資料倉庫介面（支援 Offline-First）
///
/// 定義行程資料存取的契約，包含本地快取與雲端同步操作。
abstract interface class ITripRepository {
  /// 初始化 Repository
  Future<Result<void, Exception>> init();

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

  /// 取得遠端行程列表（分頁）
  ///
  /// [page] 頁碼 / [limit] 每頁數量 / [search] 搜尋關鍵字
  Future<Result<PaginatedList<Trip>, Exception>> getRemoteTrips({int? page, int? limit, String? search});

  /// 上傳行程至遠端
  ///
  /// [trip] 要上傳的行程
  Future<Result<String, Exception>> uploadToCloud(Trip trip);

  /// 刪除遠端行程
  ///
  /// [tripId] 行程 ID
  Future<Result<void, Exception>> removeFromCloud(String tripId);

  /// 同步特定行程詳情（下載並存入本地）
  ///
  /// [tripId] 行程 ID
  Future<Result<Trip, Exception>> syncTripDetails(String tripId);

  // ========== Member Management (Remote) ==========

  /// 取得行程成員列表
  ///
  /// [tripId] 行程 ID
  Future<Result<List<TripMember>, Exception>> getTripMembers(String tripId);

  /// 更新成員角色
  ///
  /// [tripId] 行程 ID / [userId] 使用者 ID / [role] 角色
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role);

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
}
