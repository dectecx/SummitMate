import '../../../data/models/user_profile.dart';

/// Repository interface for managing authentication session data
abstract class IAuthSessionRepository {
  /// Save the session data (token and user profile)
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken});

  /// Get the current access token
  Future<String?> getAccessToken();

  /// Clear the current session
  Future<void> clearSession();

  /// Get the current user profile
  Future<UserProfile?> getUserProfile();

  /// Get the Refresh Token
  Future<String?> getRefreshToken();

  /// Check if a valid session exists
  Future<bool> hasSession();
}
