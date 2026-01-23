import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/role_constants.dart';

part 'user_profile.g.dart';

/// User Profile Model
/// Represents the authenticated user's profile data.
///
/// Role values (預留擴充):
/// - 'member': 一般會員 (預設)
/// - 'leader': 團長 (TODO: 未來開發)
/// - 'admin': 管理員 (TODO: 未來開發)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserProfile {
  final String id;

  final String email;

  final String displayName;

  final String avatar;

  final String roleId; // Role UUID

  final String roleCode; // e.g., 'ADMIN', 'LEADER'

  final List<String> permissions; // e.g., ['trip.edit', 'trip.view']

  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatar = '🐻',
    this.roleId = '',
    this.roleCode = RoleConstants.member,
    this.permissions = const [],
    this.isVerified = false,
  });

  /// 角色顯示名稱 (暫時簡單對應，之後建議移動到 Service 或 i18n)
  String get roleName {
    switch (roleCode) {
      case RoleConstants.admin:
        return '管理員';
      case RoleConstants.leader:
        return '團長';
      case RoleConstants.guide:
        return '嚮導';
      default:
        return '成員';
    }
  }

  // 保留相容性 Getters
  bool get isAdmin => roleCode == RoleConstants.admin;
  bool get isLeader => roleCode == RoleConstants.leader || roleCode == RoleConstants.admin;

  // Helper to check permission directly on model
  bool can(String permission) => permissions.contains(permission);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 處理 permissions (json 中可能是 List<dynamic> 需轉型)
    List<String> perms = [];
    if (json['permissions'] != null) {
      perms = List<String>.from(json['permissions']);
    }

    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatar: json['avatar'] as String? ?? '🐻',
      roleId: json['role_id'] as String? ?? '',
      roleCode: json['role_code'] as String? ?? RoleConstants.member,
      permissions: perms,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? displayName,
    String? avatar,
    String? roleId,
    String? roleCode,
    List<String>? permissions,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      roleCode: roleCode ?? this.roleCode,
      permissions: permissions ?? this.permissions,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() => 'UserProfile($email, $displayName, roleCode=$roleCode)';
}
