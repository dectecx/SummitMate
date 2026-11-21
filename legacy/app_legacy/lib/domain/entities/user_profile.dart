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
  String get roleName => RoleConstants.getDisplayName(role);

  bool get isAdmin => RoleConstants.isAdmin(role);
  bool get isLeader => RoleConstants.isLeader(role) || RoleConstants.isAdmin(role);

  /// 檢查權限
  bool can(String permission) => permissions.contains(permission);

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
