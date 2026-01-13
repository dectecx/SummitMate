import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../../core/error/result.dart';

/// Trip Repository 抽象介面
/// 定義行程資料存取的契約
abstract interface class ITripRepository {
  /// 初始化 Repository
  Future<Result<void, Exception>> init();

  /// 取得所有行程
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

  /// 新增行程 (本地)
  ///
  /// [trip] 欲新增的行程物件
  Future<Result<void, Exception>> addTrip(Trip trip);

  /// 更新行程
  ///
  /// [trip] 更新後的行程物件
  Future<Result<void, Exception>> updateTrip(Trip trip);

  /// 刪除行程
  ///
  /// [id] 欲刪除的行程 ID
  Future<Result<void, Exception>> deleteTrip(String id);

  /// 設定當前啟用的行程 (Active Trip)
  ///
  /// [tripId] 要設為 Active 的行程 ID
  Future<Result<void, Exception>> setActiveTrip(String tripId);

  /// 取得上次同步時間
  Future<Result<DateTime?, Exception>> getLastSyncTime();

  /// 儲存上次同步時間
  ///
  /// [time] 同步時間
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time);

  /// 取得遠端行程列表 (Cloud Management)
  Future<Result<List<Trip>, Exception>> getRemoteTrips();

  /// 上傳行程至遠端 (手動備份用)
  ///
  /// [trip] 欲上傳的行程
  /// 回傳: 上傳結果訊息
  Future<Result<String, Exception>> uploadTripToRemote(Trip trip);

  /// 刪除遠端行程
  ///
  /// [id] 欲刪除的遠端行程 ID
  Future<Result<void, Exception>> deleteRemoteTrip(String id);

  /// 完整上傳行程 (包含行程表與裝備)
  ///
  /// [trip] 行程物件
  /// [itineraryItems] 行程節點列表
  /// [gearItems] 裝備列表
  /// 回傳: 上傳結果訊息
  Future<Result<String, Exception>> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  });

  /// 清除所有本地行程資料 (登出時使用)
  Future<Result<void, Exception>> clearAll();

  /// 取得行程成員列表 (Remote)
  ///
  /// [tripId] 行程 ID
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId);

  /// 更新成員角色 (Remote)
  ///
  /// [tripId] 行程 ID
  /// [userId] 目標成員 ID
  /// [role] 新角色身分代碼 (參考 RoleConstants)
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role);

  /// 移除成員 (Remote)
  ///
  /// [tripId] 行程 ID
  /// [userId] 目標成員 ID
  Future<Result<void, Exception>> removeMember(String tripId, String userId);

  /// 新增成員 (透過 Email)
  ///
  /// [tripId] 行程 ID
  /// [email] 成員 Email
  /// [role] 初始角色
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'});

  /// 新增成員 (透過 User ID)
  ///
  /// [tripId] 行程 ID
  /// [userId] 成員 User ID
  /// [role] 初始角色
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'});

  /// 透過 Email 搜尋使用者
  ///
  /// [email] 使用者 Email
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email);

  /// 透過 ID 搜尋使用者
  ///
  /// [userId] 使用者 ID
  Future<Result<UserProfile, Exception>> searchUserById(String userId);
}
