/// 角色代碼常數定義
///
/// 對應後端 Roles 表中的 code 欄位
class RoleConstants {
  static const String admin = 'ADMIN';
  static const String leader = 'LEADER';
  static const String guide = 'GUIDE';
  static const String member = 'MEMBER';

  static const Map<String, String> displayName = {admin: '管理員', leader: '團長', guide: '嚮導', member: '成員'};
}
