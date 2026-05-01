import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:summitmate/core/constants/role_constants.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// 使用者個人資料領域實體 (Domain Entity)
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    required String email,
    required String displayName,
    @Default('🐻') String avatar,
    @Default('') String roleId,
    @Default(RoleConstants.member) String role,
    @Default([]) List<String> permissions,
    @Default(false) bool isVerified,
  }) = _UserProfile;

  /// 角色顯示名稱
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

  bool get isAdmin => role == RoleConstants.admin;
  bool get isLeader => role == RoleConstants.leader || role == RoleConstants.admin;

  /// 檢查權限
  bool can(String permission) => permissions.contains(permission);

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
