/// 角色代碼常數定義
///
/// 對應後端 Roles 表中的 code 欄位
class RoleConstants {
  static const String admin = 'admin';
  static const String leader = 'leader';
  static const String guide = 'guide';
  static const String member = 'member';

  /// 檢查兩角色代碼是否相等（不區分大小寫）
  static bool isEqual(String? role1, String? role2) {
    if (role1 == null || role2 == null) return false;
    return role1.trim().toLowerCase() == role2.trim().toLowerCase();
  }

  /// 檢查角色是否為 Admin（不區分大小寫）
  static bool isAdmin(String? role) => isEqual(role, admin);

  /// 檢查角色是否為 Leader（不區分大小寫）
  static bool isLeader(String? role) => isEqual(role, leader);

  /// 檢查角色是否為 Guide（不區分大小寫）
  static bool isGuide(String? role) => isEqual(role, guide);

  /// 檢查角色是否為 Member（不區分大小寫）
  static bool isMember(String? role) => isEqual(role, member);

  /// 取得角色顯示名稱（不區分大小寫）
  static String getDisplayName(String? role) {
    if (role == null) return '未知';
    final normalized = role.trim().toLowerCase();
    return displayName[normalized] ?? role;
  }

  static const Map<String, String> displayName = {admin: '管理員', leader: '團長', guide: '嚮導', member: '成員'};
}
