import '../../../data/models/user_profile.dart';
import '../../../services/interfaces/i_auth_token_provider.dart';

/// Repository interface for managing authentication session data
abstract class IAuthSessionRepository implements IAuthTokenProvider {
  /// Save the session data (token and user profile)
  Future<void> saveSession(String token, UserProfile user);

  /// Clear the current session
  Future<void> clearSession();

  /// Get the current user profile
  Future<UserProfile?> getUserProfile();

  /// Check if a valid session exists
  Future<bool> hasSession();
}
