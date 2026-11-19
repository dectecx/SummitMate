import 'package:flutter/material.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';
import '../common/user_avatar.dart';

/// 成員列表項目 Widget
///
/// 顯示單一成員的資訊，包含頭像、名稱、角色等。
/// 可選的設定按鈕用於管理成員權限。
class MemberListTile extends StatelessWidget {
  /// 成員實體
  final TripMember member;

  /// 是否為當前使用者
  final bool isSelf;

  /// 是否為行程擁有者
  final bool isOwner;

  /// 是否可編輯此成員
  final bool canEdit;

  /// 點擊設定按鈕的回調
  final VoidCallback? onSettingsTap;

  const MemberListTile({
    super.key,
    required this.member,
    required this.isSelf,
    required this.isOwner,
    required this.canEdit,
    this.onSettingsTap,
  });

  /// 取得本地化角色名稱
  String _getRoleName(String code) {
    return RoleConstants.getDisplayName(code);
  }

  @override
  Widget build(BuildContext context) {
    final role = member.role;

    // Determine role style
    String roleText;
    IconData roleIcon;
    Color? roleColor;

    if (RoleConstants.isAdmin(role) || RoleConstants.isLeader(role) || isOwner) {
      roleText = _getRoleName(RoleConstants.leader);
      if (isOwner) roleText += ' (擁)';
      roleIcon = Icons.stars;
      roleColor = Colors.amber;
    } else if (RoleConstants.isGuide(role)) {
      roleText = _getRoleName(RoleConstants.guide);
      roleIcon = Icons.hiking;
      roleColor = Colors.green;
    } else {
      roleText = _getRoleName(RoleConstants.member);
      roleIcon = Icons.person_outline;
      roleColor = null;
    }

    return ListTile(
      leading: UserAvatar(
        avatar: member.avatar,
        fallbackText: member.name,
        radius: 20,
      ),
      title: Text(member.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 16, color: roleColor),
              const SizedBox(width: 4),
              Text(
                roleText,
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text('ID: ${member.userId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      trailing: canEdit ? OutlinedButton(onPressed: onSettingsTap, child: const Text('設定')) : null,
    );
  }
}
