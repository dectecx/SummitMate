import '../core/di.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/interfaces/i_auth_session_repository.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// Authentication Service
/// Handles high-level auth logic (API calls + Session coordination).
/// Delegates storage to [IAuthSessionRepository].
class AuthService {
  static const String _source = 'AuthService';

  final GasApiClient _apiClient;
  final IAuthSessionRepository _sessionRepo;

  AuthService({GasApiClient? apiClient, required IAuthSessionRepository sessionRepository})
    : _apiClient = apiClient ?? getIt<GasApiClient>(),
      _sessionRepo = sessionRepository;

  // ============================================================
  // === PUBLIC API ===
  // ============================================================

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    try {
      LogService.info('嘗試註冊: $email', source: _source);

      // 1. Call API
      final response = await _apiClient.post({
        'action': 'auth_register',
        'email': email,
        'password': password,
        'displayName': displayName,
        'avatar': avatar,
      });

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        final token = apiResponse.data['authToken'] as String;

        // 2. Save Session
        await _sessionRepo.saveSession(token, user);

        LogService.info('註冊成功: ${user.email}', source: _source);
        return AuthResult.success(user: user, token: token);
      } else {
        LogService.warning('註冊失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(code: apiResponse.code, message: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('註冊例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(code: 'NETWORK_ERROR', message: '網路錯誤，請稍後再試');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      LogService.info('嘗試登入: $email', source: _source);

      // 1. Call API
      final response = await _apiClient.post({'action': 'auth_login', 'email': email, 'password': password});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        final token = apiResponse.data['authToken'] as String;

        // 2. Save Session
        await _sessionRepo.saveSession(token, user);

        LogService.info('登入成功: ${user.email}', source: _source);
        return AuthResult.success(user: user, token: token);
      } else {
        LogService.warning('登入失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(code: apiResponse.code, message: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('登入例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(code: 'NETWORK_ERROR', message: '網路錯誤，請稍後再試');
    }
  }

  /// Validate current session with server
  Future<AuthResult> validateSession() async {
    final token = await _sessionRepo.getAuthToken();
    if (token == null) {
      return AuthResult.failure(code: 'NO_TOKEN', message: '未登入');
    }

    try {
      // 1. Call API
      final response = await _apiClient.post({
        'action': 'auth_validate',
        'authToken': token, // Explicitly passed in body here, though interceptor would also inject it
      });

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);

        // 2. Refresh Session
        await _sessionRepo.saveSession(token, user);

        return AuthResult.success(user: user, token: token);
      } else {
        // Token invalid -> Clear Session
        await logout();
        return AuthResult.failure(code: apiResponse.code, message: apiResponse.message);
      }
    } catch (e) {
      // Network error -> Check local cache (Offline Support)
      LogService.warning('驗證 Token 失敗 (可能離線): $e', source: _source);
      final cachedUser = await getCachedUserProfile();
      if (cachedUser != null) {
        return AuthResult.success(user: cachedUser, token: token, isOffline: true);
      }
      return AuthResult.failure(code: 'NETWORK_ERROR', message: '無法連線伺服器');
    }
  }

  /// Delete user account (soft delete)
  Future<AuthResult> deleteAccount() async {
    final token = await _sessionRepo.getAuthToken();
    if (token == null) {
      return AuthResult.failure(code: 'NO_TOKEN', message: '未登入');
    }

    try {
      final response = await _apiClient.post({'action': 'auth_delete_user'});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        await logout();
        LogService.info('帳號已刪除', source: _source);
        return AuthResult.success();
      } else {
        return AuthResult.failure(code: apiResponse.code, message: apiResponse.message);
      }
    } catch (e) {
      return AuthResult.failure(code: 'NETWORK_ERROR', message: '網路錯誤');
    }
  }

  /// Logout
  Future<void> logout() async {
    await _sessionRepo.clearSession();
    LogService.info('已登出', source: _source);
  }

  /// Get stored auth token
  Future<String?> getAuthToken() => _sessionRepo.getAuthToken();

  /// Get cached user profile
  Future<UserProfile?> getCachedUserProfile() => _sessionRepo.getUserProfile();

  /// Check if user is logged in
  Future<bool> isLoggedIn() => _sessionRepo.hasSession();
}

/// Result of an authentication operation
class AuthResult {
  final bool isSuccess;
  final UserProfile? user;
  final String? token;
  final String? errorCode;
  final String? errorMessage;
  final bool isOffline;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.errorCode,
    this.errorMessage,
    this.isOffline = false,
  });

  factory AuthResult.success({UserProfile? user, String? token, bool isOffline = false}) {
    return AuthResult._(isSuccess: true, user: user, token: token, isOffline: isOffline);
  }

  factory AuthResult.failure({required String code, required String message}) {
    return AuthResult._(isSuccess: false, errorCode: code, errorMessage: message);
  }
}
