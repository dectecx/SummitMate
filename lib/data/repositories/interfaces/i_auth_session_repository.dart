import '../../../data/models/user_profile.dart';
import '../../../services/interfaces/i_auth_token_provider.dart';

/// Repository interface for managing authentication session data
abstract class IAuthSessionRepository implements IAuthTokenProvider {
  /// Save the session data (token and user profile)
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken});

  /// Clear the current session
  Future<void> clearSession();

  /// Get the current user profile
  Future<UserProfile?> getUserProfile();

  /// Get the Refresh Token
  Future<String?> getRefreshToken();

  /// Check if a valid session exists
  Future<bool> hasSession();
}
