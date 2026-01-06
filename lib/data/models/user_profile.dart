import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// User Profile Model
/// Represents the authenticated user's profile data.
///
/// Role values (預留擴充):
/// - 'member': 一般會員 (預設)
/// - 'leader': 團長 (TODO: 未來開發)
/// - 'admin': 管理員 (TODO: 未來開發)
@HiveType(typeId: 10)
@JsonSerializable()
class UserProfile extends HiveObject {
  @HiveField(0)
  final String uuid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String avatar;

  /// Role: 'member', 'leader', 'admin' (預留擴充)
  @HiveField(4)
  final String role;

  UserProfile({
    required this.uuid,
    required this.email,
    required this.displayName,
    this.avatar = '🐻',
    this.role = 'member',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// Check if user has leader role
  bool get isLeader => role == 'leader' || role == 'admin';

  /// Check if user has admin role
  bool get isAdmin => role == 'admin';

  @override
  String toString() => 'UserProfile($email, $displayName, role=$role)';
}
