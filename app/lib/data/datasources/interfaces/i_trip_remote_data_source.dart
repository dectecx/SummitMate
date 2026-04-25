import '../../../core/models/paginated_list.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';

/// 行程 (Trip) 的遠端資料來源介面
///
/// 負責定義與後端 API 進行行程資料交換的操作。
abstract interface class ITripRemoteDataSource {
  /// 取得雲端行程列表 (支援分頁與搜尋)
  Future<PaginatedList<Trip>> getTrips({String? cursor, int? limit, String? search});

  /// 上傳單一行程 (僅行程 Meta)
  ///
  /// [trip] 行程資料
  /// 回傳: 新行程 ID
  Future<String> uploadTrip(Trip trip);

  /// 更新行程
  ///
  /// [trip] 更新後的行程資料
  Future<void> updateTrip(Trip trip);

  /// 刪除行程
  ///
  /// [tripId] 行程 ID
  Future<void> deleteTrip(String tripId);

  /// 取得行程成員列表
  ///
  /// [tripId] 行程 ID
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId);

  /// 更新成員角色
  ///
  /// [tripId] 行程 ID
  /// [userId] 成員 User ID
  /// [role] 新角色 (e.g. 'guide', 'member')
  Future<void> updateMemberRole(String tripId, String userId, String role);

  /// 移除成員
  ///
  /// [tripId] 行程 ID
  /// [userId] 成員 User ID
  Future<void> removeMember(String tripId, String userId);

  /// 新增成員 (透過 Email)
  ///
  /// [tripId] 行程 ID
  /// [email] 成員 Email
  /// [role] 初始角色
  Future<void> addMemberByEmail(String tripId, String email, {String role = 'member'});

  /// 新增成員 (透過 User ID)
  ///
  /// [tripId] 行程 ID
  /// [userId] 成員 User ID
  /// [role] 初始角色
  Future<void> addMemberById(String tripId, String userId, {String role = 'member'});

  /// 透過 Email 搜尋使用者
  ///
  /// [email] 使用者 Email
  Future<UserProfile> searchUserByEmail(String email);

  /// 透過 ID 搜尋使用者
  ///
  /// [userId] 使用者 ID
  Future<UserProfile> searchUserById(String userId);
}
