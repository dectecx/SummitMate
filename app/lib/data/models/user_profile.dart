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

  final String role; // e.g., 'ADMIN', 'LEADER'

  final List<String> permissions; // e.g., ['trip.edit', 'trip.view']

  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatar = '🐻',
    this.roleId = '',
    this.role = RoleConstants.member,
    this.permissions = const [],
    this.isVerified = false,
  });

  /// 角色顯示名稱 (暫時簡單對應，之後建議移動到 Service 或 i18n)
  String get roleName {
    switch (role) {
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
  bool get isAdmin => role == RoleConstants.admin;
  bool get isLeader => role == RoleConstants.leader || role == RoleConstants.admin;

  // Helper to check permission directly on model
  bool can(String permission) => permissions.contains(permission);

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? displayName,
    String? avatar,
    String? roleId,
    String? role,
    List<String>? permissions,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() => 'UserProfile($email, $displayName, role=$role)';
}
