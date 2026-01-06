import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/di.dart';
import '../data/models/user_profile.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// Authentication Service
/// Handles login, registration, token storage, and session management.
class AuthService {
  static const String _source = 'AuthService';

  // Secure Storage Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserProfile = 'user_profile';

  final GasApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  AuthService({
    GasApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? getIt<GasApiClient>(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ============================================================
  // === PUBLIC API ===
  // ============================================================

  /// Register a new user
  /// Returns [AuthResult] with success/failure and user data.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    try {
      LogService.info('嘗試註冊: $email', source: _source);

      final response = await _apiClient.post({
        'action': 'auth_register',
        'email': email,
        'password': password,
        'displayName': displayName,
        'avatar': avatar,
      });

      final apiResponse = GasApiResponse.fromJsonString(response.body);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        final token = apiResponse.data['authToken'] as String;

        // Store credentials
        await _saveSession(token, user);

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
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      LogService.info('嘗試登入: $email', source: _source);

      final response = await _apiClient.post({
        'action': 'auth_login',
        'email': email,
        'password': password,
      });

      final apiResponse = GasApiResponse.fromJsonString(response.body);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        final token = apiResponse.data['authToken'] as String;

        await _saveSession(token, user);

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
  /// Returns true if session is valid, false otherwise.
  Future<AuthResult> validateSession() async {
    final token = await getAuthToken();
    if (token == null) {
      return AuthResult.failure(code: 'NO_TOKEN', message: '未登入');
    }

    try {
      final response = await _apiClient.post({
        'action': 'auth_validate',
        'authToken': token,
      });

      final apiResponse = GasApiResponse.fromJsonString(response.body);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        // Refresh stored profile with latest from server
        await _saveSession(token, user);
        return AuthResult.success(user: user, token: token);
      } else {
        // Token is invalid or account disabled - clear local session
        await logout();
        return AuthResult.failure(code: apiResponse.code, message: apiResponse.message);
      }
    } catch (e) {
      // Network error - keep local session (offline mode)
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
    final token = await getAuthToken();
    if (token == null) {
      return AuthResult.failure(code: 'NO_TOKEN', message: '未登入');
    }

    try {
      final response = await _apiClient.post({
        'action': 'auth_delete_user',
        'authToken': token,
      });

      final apiResponse = GasApiResponse.fromJsonString(response.body);

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

  /// Logout - clear all stored credentials
  Future<void> logout() async {
    await _secureStorage.delete(key: _keyAuthToken);
    await _secureStorage.delete(key: _keyUserProfile);
    LogService.info('已登出', source: _source);
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _keyAuthToken);
  }

  /// Get cached user profile from secure storage
  Future<UserProfile?> getCachedUserProfile() async {
    final json = await _secureStorage.read(key: _keyUserProfile);
    if (json == null) return null;

    try {
      return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      LogService.warning('無法解析快取使用者資料: $e', source: _source);
      return null;
    }
  }

  /// Check if user is logged in (has cached credentials)
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // === PRIVATE HELPERS ===
  // ============================================================

  Future<void> _saveSession(String token, UserProfile user) async {
    await _secureStorage.write(key: _keyAuthToken, value: token);
    await _secureStorage.write(key: _keyUserProfile, value: jsonEncode(user.toJson()));
  }
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
