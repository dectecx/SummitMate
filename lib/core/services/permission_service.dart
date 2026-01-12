import 'package:get_it/get_it.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../data/models/trip.dart';
import '../../core/constants/role_constants.dart';

/// 權限管理服務
///
/// 負責集中處理所有的權限判斷邏輯
class PermissionService {
  final IAuthService _authService;

  PermissionService(this._authService);

  // 工廠方法供 DI 使用
  factory PermissionService.di() => PermissionService(GetIt.I<IAuthService>());

  /// 檢查是否擁有特定權限代碼
  Future<bool> can(String permission) async {
    final user = await _authService.getCachedUserProfile();
    if (user == null) return false;
    return user.permissions.contains(permission) || user.roleCode == RoleConstants.admin;
  }

  /// 同步檢查 (僅限已確認 UserProfile 載入的場景，例如 UI Widget 中)
  bool canSync(String permission) {
    // 注意: 這裡假設外部已確保 UserProfile 存在，否則無法同步取得
    // 實務上建議使用 can() 非同步方法，或是透過 Provider 傳入 UserProfile
    return true; // 暫時回傳 true，由調用端的 AuthProvider 決定
  }

  // === 特定業務邏輯檢查 ===

  /// 是否可以編輯行程
  /// 規則: 擁有 'trip.edit' 權限
  Future<bool> canEditTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    if (user == null) return false;

    // Admin 擁有絕對權限
    if (user.roleCode == RoleConstants.admin) return true;

    // 基本權限檢查
    if (!user.permissions.contains('trip.edit')) return false;

    // [進階規則] 雖然是嚮導(Guide)有 'trip.edit'，但通常也需要確保是該行程的成員
    // 但目前資料結構 Trip 內沒有 member list，僅有 createdBy
    // V1 簡化規則: 只要有 'trip.edit' 就可以編輯 (假設只會看到自己加入的行程)

    // 如果需要嚴格限制只能編輯自己建立的或被邀請的:
    // return trip.createdBy == user.id || isInvited...

    return true;
  }

  /// 是否可以刪除行程
  /// 規則: 擁有 'trip.delete' 權限 且 (是建立者 或 Admin)
  Future<bool> canDeleteTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    if (user == null) return false;

    if (user.roleCode == RoleConstants.admin) return true;

    if (!user.permissions.contains('trip.delete')) return false;

    // 只有建立者可以刪除 (防止嚮導誤刪，雖然嚮導通常沒 delete 權限)
    return trip.createdBy == user.id;
  }

  /// 是否可以移交團長
  /// 規則: 擁有 'trip.transfer' 且 是建立者
  Future<bool> canTransferTrip(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    if (user == null) return false;

    if (user.roleCode == RoleConstants.admin) return true;

    return user.permissions.contains('trip.transfer') && trip.createdBy == user.id;
  }

  /// 是否可以管理成員
  /// 規則: 擁有 'member.manage' 且 (是建立者 或 Admin)
  Future<bool> canManageMembers(Trip trip) async {
    final user = await _authService.getCachedUserProfile();
    if (user == null) return false;

    if (user.roleCode == RoleConstants.admin) return true;

    if (!user.permissions.contains('member.manage')) return false;

    return trip.createdBy == user.id;
  }
}
