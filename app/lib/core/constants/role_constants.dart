/// 角色代碼常數定義
///
/// 對應後端 Roles 表中的 code 欄位
class RoleConstants {
  static const String admin = 'admin';
  static const String leader = 'leader';
  static const String guide = 'guide';
  static const String member = 'member';

  static const Map<String, String> displayName = {admin: '管理員', leader: '團長', guide: '嚮導', member: '成員'};
}
