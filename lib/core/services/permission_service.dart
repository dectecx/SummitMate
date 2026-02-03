import '../../domain/interfaces/i_auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/trip.dart';
import '../../data/models/message.dart';
import '../../core/constants/role_constants.dart';

/// 權限管理服務
///
/// 負責集中處理所有的權限判斷邏輯
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
    if (user.roleCode == RoleConstants.admin) return true;
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
    if (user.roleCode == RoleConstants.admin) return true;

    // 0. 團長 (Leader/Owner) 絕對擁有編輯權限
    if (trip.userId == user.id) return true;

    // 1. 必須是行程成員 (基本門檻)
    if (!trip.members.contains(user.id)) return false;

    // 2. 必須擁有 'trip.edit' 權限 (角色賦予)
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
    if (user.roleCode == RoleConstants.admin) return true;

    // 0. 團長 (Leader/Owner) 絕對擁有刪除權限
    if (trip.userId == user.id) return true;

    // 1. 必須是行程成員 (通常只有團長/嚮導能刪除)
    if (!trip.members.contains(user.id)) return false;

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
    if (user.roleCode == RoleConstants.admin) return true;

    if (!trip.members.contains(user.id)) return false;

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
    if (user.roleCode == RoleConstants.admin) return true;

    if (!trip.members.contains(user.id)) return false;

    return user.permissions.contains('member.manage');
  }

  /// 是否可以刪除留言 (Sync)
  bool canDeleteMessageSync(UserProfile? user, Message message) {
    if (user == null) return false;
    if (user.roleCode == RoleConstants.admin) return true;

    // 用戶只能刪除自己的留言
    return message.userId == user.id;
  }
}
