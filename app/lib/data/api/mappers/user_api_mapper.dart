import '../../models/user_profile.dart';
import '../models/user_api_models.dart';

/// User API Model ↔ Domain Model 轉換
class UserApiMapper {
  /// UserResponse → UserProfile (domain model)
  static UserProfile fromResponse(UserResponse response) {
    return UserProfile(
      id: response.id,
      email: response.email,
      displayName: response.displayName,
      avatar: response.avatar ?? '🐻',
      roleId: response.roleId,
      role: response.role,
      permissions: response.permissions,
      isVerified: response.isVerified,
    );
  }

  /// UserProfile → UserUpdateRequest
  static UserUpdateRequest toUpdateRequest(UserProfile profile) {
    return UserUpdateRequest(displayName: profile.displayName, avatar: profile.avatar);
  }
}
