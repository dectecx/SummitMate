import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';
import '../../core/constants/role_constants.dart';

/// 權限管理服務
///
/// 負責集中處理所有的權限判斷邏輯
@lazySingleton
class PermissionService {
  final IAuthService _authService;

  PermissionService(this._authService);

  /// 檢查是否擁有特定權限代碼 (Async)
  Future<bool> can(String permission) async {
    final user = await _authService.getCachedUserProfile();
    return canSync(user, permission);
  }

  /// 檢查是否擁有特定權限代碼 (Sync)
  bool canSync(UserProfile? user, String permission) {
    if (user == null) return false;
    // Admin 擁有所有權限
    if (user.role == RoleConstants.admin) return true;
    return user.permissions.contains(permission);
  }

  // === 特定業務邏輯檢查 (Trip) ===

  /// 是否可以編輯行程 (Async)
  Future<bool> canEditTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    return canEditTripSync(user, trip);
  }

  /// 是否可以編輯行程 (Sync)
  bool canEditTripSync(UserProfile? user, Trip trip) {
    if (user == null) return false;
    if (user.role == RoleConstants.admin) return true;

    // 0. 團長 (Leader/Owner) 絕對擁有編輯權限
    if (trip.userId == user.id) return true;

    // 1. 必須擁有 'trip.edit' 權限 (角色賦予)
    if (!user.permissions.contains('trip.edit')) return false;

    return true;
  }

  /// 是否可以刪除行程 (Async)
  Future<bool> canDeleteTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    return canDeleteTripSync(user, trip);
  }

  /// 是否可以刪除行程 (Sync)
  bool canDeleteTripSync(UserProfile? user, Trip trip) {
    if (user == null) return false;
    if (user.role == RoleConstants.admin) return true;

    // 0. 團長 (Leader/Owner) 絕對擁有刪除權限
    if (trip.userId == user.id) return true;

    return user.permissions.contains('trip.delete');
  }

  /// 是否可以移交團長 (Async)
  Future<bool> canTransferTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    return canTransferTripSync(user, trip);
  }

  /// 是否可以移交團長 (Sync)
  bool canTransferTripSync(UserProfile? user, Trip trip) {
    if (user == null) return false;
    if (user.role == RoleConstants.admin) return true;

    return user.permissions.contains('trip.transfer');
  }

  /// 是否可以管理成員 (Async)
  Future<bool> canManageMembers(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    return canManageMembersSync(user, trip);
  }

  /// 是否可以管理成員 (Sync)
  bool canManageMembersSync(UserProfile? user, Trip trip) {
    if (user == null) return false;
    if (user.role == RoleConstants.admin) return true;

    // 行程擁有者 (Owner) 具有成員管理權限
    if (trip.userId == user.id) return true;

    return user.permissions.contains('member.manage');
  }

  /// 是否可以管理行程成員（含行程內 TripMember 角色判斷）
  ///
  /// 相比 [canManageMembersSync]，此方法額外考量使用者在該行程中的
  /// trip-level 角色（leader / admin），適用於已載入成員列表的場景。
  ///
  /// [currentUserId] 當前使用者 ID
  /// [trip] 行程實體
  /// [members] 該行程已載入的成員列表
  bool canManageTripMembersWithTripRole({
    required String currentUserId,
    required Trip trip,
    required List<TripMember> members,
  }) {
    // 行程擁有者 (Owner) 具有成員管理權限
    if (trip.userId == currentUserId) return true;

    // 查找當前使用者在此行程中的 trip-level 角色
    final me = members.where((m) => m.userId == currentUserId).firstOrNull;
    if (me == null) return false;

    return me.role == RoleConstants.leader || me.role == RoleConstants.admin;
  }

  /// 是否為行程擁有者
  ///
  /// 用於取代 widget 層直接比對 `trip.userId == userId` 的散落寫法。
  bool isOwner(Trip trip, String? userId) {
    if (userId == null) return false;
    return trip.userId == userId;
  }

  /// 是否可以刪除留言 (Sync)
  bool canDeleteMessageSync(UserProfile? user, Message message) {
    if (user == null) return false;
    if (user.role == RoleConstants.admin) return true;

    // 用戶只能刪除自己的留言
    return message.userId == user.id;
  }
}
