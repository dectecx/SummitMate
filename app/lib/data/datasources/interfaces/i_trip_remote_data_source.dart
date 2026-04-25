import '../../../core/models/paginated_list.dart';
import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../../core/error/result.dart';

/// 行程 (Trip) 的遠端資料來源介面
abstract interface class ITripRemoteDataSource {
  /// 從後端獲取使用者的行程列表 (支援分頁)
  Future<Result<PaginatedList<Trip>, Exception>> getRemoteTrips({
    int? page,
    int? limit,
    String? search,
  });

  /// 上傳行程至後端
  Future<Result<String, Exception>> uploadTrip(Trip trip);

  /// 從後端刪除行程
  Future<Result<void, Exception>> deleteTrip(String tripId);

  /// 同步行程詳情
  Future<Result<Trip, Exception>> getTripDetails(String tripId);

  // ========== Member Management ==========

  /// 取得行程成員
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId);

  /// 更新成員角色
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role);

  /// 移除成員
  Future<Result<void, Exception>> removeMember(String tripId, String userId);

  /// 新增成員 (Email)
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'});

  /// 新增成員 (ID)
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'});

  /// 搜尋使用者 (Email)
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email);

  /// 搜尋使用者 (ID)
  Future<Result<UserProfile, Exception>> searchUserById(String userId);
}
