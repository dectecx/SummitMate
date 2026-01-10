import '../../../data/models/user_profile.dart';

/// Authentication Result
/// Represents the outcome of an authentication operation.
class AuthResult {
  final bool isSuccess;
  final UserProfile? user;
  final String? errorCode;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresVerification;
  final bool isOffline;

  const AuthResult({
    required this.isSuccess,
    this.user,
    this.errorCode,
    this.errorMessage,
    this.accessToken,
    this.refreshToken,
    this.requiresVerification = false,
    this.isOffline = false,
  });

  factory AuthResult.success({UserProfile? user, String? accessToken, String? refreshToken, bool isOffline = false}) {
    return AuthResult(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      isOffline: isOffline,
    );
  }

  factory AuthResult.failure({required String errorCode, String? errorMessage}) {
    return AuthResult(isSuccess: false, errorCode: errorCode, errorMessage: errorMessage);
  }

  factory AuthResult.requiresVerification({String? errorMessage, UserProfile? user}) {
    return AuthResult(
      isSuccess: true, // The operation succeeded, but verification is needed
      user: user,
      requiresVerification: true,
      errorCode: 'REQUIRES_VERIFICATION',
      errorMessage: errorMessage,
    );
  }
}

/// Third-party authentication provider for OAuth SSO
enum OAuthProvider { google, facebook, apple, line }

/// Abstract Authentication Service Interface
/// All authentication backends implement this interface.
/// This enables swappable auth implementations:
/// - GasAuthService (current)
/// - FirebaseAuthService (future)
/// - AzureAuthService (future)
/// - OAuthSSOService (future)
abstract class IAuthService {
  /// Register a new user with email and password
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  });

  /// Update user profile (display name, avatar)
  Future<AuthResult> updateProfile({String? displayName, String? avatar});

  /// Login with email and password
  Future<AuthResult> login({required String email, required String password});

  /// Login with third-party OAuth provider
  Future<AuthResult> loginWithProvider(OAuthProvider provider);

  /// Verify email with verification code
  Future<AuthResult> verifyEmail({required String email, required String code});

  /// Resend verification code
  Future<AuthResult> resendVerificationCode({required String email});

  /// Validate current session with server
  Future<AuthResult> validateSession();

  /// Refresh the access token using refresh token
  Future<AuthResult> refreshToken();

  /// Logout and clear session
  Future<void> logout();

  /// Delete user account (soft delete)
  Future<AuthResult> deleteAccount();

  /// Get the current access token
  Future<String?> getAccessToken();

  /// Get the current refresh token
  Future<String?> getRefreshToken();

  /// Get cached user profile
  Future<UserProfile?> getCachedUserProfile();

  /// Check if user is logged in (has valid session)
  Future<bool> isLoggedIn();

  /// Check if currently in offline mode
  bool get isOfflineMode;
}
