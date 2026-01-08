import 'package:flutter/foundation.dart';
import '../../core/di.dart';
import '../../data/models/user_profile.dart';
import '../../services/interfaces/i_auth_service.dart';
import '../../services/log_service.dart';
import '../../core/constants/gas_error_codes.dart';

/// Auth Provider
/// Manages the global authentication state for the app.
///
/// Features:
/// - Automatically restores session on app launch
/// - Supports offline mode (cached credentials)
/// - Provides user profile access throughout the app
class AuthProvider extends ChangeNotifier {
  static const String _source = 'AuthProvider';

  final IAuthService _authService;

  AuthState _state = AuthState.loading;
  UserProfile? _user;
  bool _isOffline = false;

  AuthProvider({IAuthService? authService}) : _authService = authService ?? getIt<IAuthService>() {
    _initSession();
  }

  // ============================================================
  // === GETTERS ===
  // ============================================================

  /// Current authentication state
  AuthState get state => _state;

  /// Whether the user is authenticated (online or offline)
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Whether the session is offline (cached credentials, not verified)
  bool get isOffline => _isOffline;

  /// Current user profile (null if not authenticated)
  UserProfile? get user => _user;

  /// Current user's display name
  String get displayName => _user?.displayName ?? '訪客';

  /// Current user's avatar
  String get avatar => _user?.avatar ?? '🐻';

  /// Current user's access token
  Future<String?> get accessToken => _authService.getAccessToken();

  // ============================================================
  // === PUBLIC METHODS ===
  // ============================================================

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    final result = await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
      avatar: avatar,
    );

    if (result.isSuccess) {
      _user = result.user;
      _isOffline = false;

      // Only change state and notify if verified
      // For unverified users, RegisterScreen will handle navigation to VerificationScreen
      // Calling notifyListeners for unverified would trigger HomeScreen rebuild and break navigation
      if (result.user?.isVerified == true) {
        _state = AuthState.authenticated;
        notifyListeners();
      }
      // For unverified users, state stays as is (loading/unauthenticated)
      // so HomeScreen doesn't rebuild and RegisterScreen can navigate to VerificationScreen
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }

    return result;
  }

  /// Login with email and password
  Future<AuthResult> login({required String email, required String password}) async {
    final result = await _authService.login(email: email, password: password);

    if (result.isSuccess) {
      _user = result.user;
      _isOffline = result.isOffline;
      _state = (result.user?.isVerified == true) ? AuthState.authenticated : AuthState.unauthenticated;
    } else {
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
    return result;
  }

  /// Logout the current user
  /// Shows warning if offline (user cannot log back in without network)
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isOffline = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
    LogService.info('使用者已登出', source: _source);
  }

  /// Delete user account (soft delete)
  Future<AuthResult> deleteAccount() async {
    final result = await _authService.deleteAccount();
    if (result.isSuccess) {
      _user = null;
      _isOffline = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
    return result;
  }

  /// Validate current session with server (call periodically or on app resume)
  Future<void> validateSession() async {
    final result = await _authService.validateSession();

    if (result.isSuccess) {
      _user = result.user;
      _isOffline = result.isOffline;
      // Only authenticate if verified
      _state = (result.user?.isVerified == true) ? AuthState.authenticated : AuthState.unauthenticated;
    } else {
      // Session invalidated (e.g., account deleted by admin)
      if (result.errorCode == GasErrorCodes.authAccountDisabled ||
          result.errorCode == GasErrorCodes.authAccessTokenInvalid) {
        _user = null;
        _isOffline = false;
        _state = AuthState.unauthenticated;
        LogService.warning('Session 已失效: ${result.errorMessage}', source: _source);
      }
    }

    notifyListeners();
  }

  /// Update user profile (display name, avatar)
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    final result = await _authService.updateProfile(displayName: displayName, avatar: avatar);

    if (result.isSuccess) {
      _user = result.user; // Update local user state
      notifyListeners();
    }

    return result;
  }

  /// Skip login and continue as guest
  /// Guest mode allows limited functionality without cloud sync
  void skipLogin() {
    LogService.info('略過登入，以訪客身分繼續', source: _source);
    _user = null;
    _isOffline = true;
    _state = AuthState.authenticated; // Allow guest to access app
    notifyListeners();
  }

  // ============================================================
  // === PRIVATE METHODS ===
  // ============================================================

  /// Initialize session on app launch
  Future<void> _initSession() async {
    LogService.debug('初始化 Session...', source: _source);

    final isLoggedIn = await _authService.isLoggedIn();

    if (!isLoggedIn) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    // Try to validate with server, fall back to cached credentials
    final result = await _authService.validateSession();

    if (result.isSuccess) {
      _user = result.user;
      _isOffline = result.isOffline;
      _user = result.user;
      _isOffline = result.isOffline;
      _state = (result.user?.isVerified == true) ? AuthState.authenticated : AuthState.unauthenticated;
      LogService.info('Session 恢復成功${result.isOffline ? " (離線模式)" : ""}', source: _source);
    } else {
      // Cached credentials are invalid
      _state = AuthState.unauthenticated;
      LogService.warning('Session 恢復失敗: ${result.errorMessage}', source: _source);
    }

    notifyListeners();
  }
}

/// Authentication State
enum AuthState {
  /// Initial loading state
  loading,

  /// User is authenticated (online or offline)
  authenticated,

  /// User is not authenticated
  unauthenticated,
}
