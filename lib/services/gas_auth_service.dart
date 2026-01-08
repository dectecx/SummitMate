import '../core/constants.dart';
import '../core/constants/gas_error_codes.dart';
import '../core/di.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/interfaces/i_auth_session_repository.dart';
import 'gas_api_client.dart';
import 'interfaces/i_auth_service.dart';
import 'interfaces/i_token_validator.dart';
import 'jwt_token_validator.dart';
import 'log_service.dart';

/// GAS (Google Apps Script) Authentication Service
/// Implements [IAuthService] for GAS backend with JWT tokens.
/// This can be swapped with FirebaseAuthService, etc. via DI.
class GasAuthService implements IAuthService {
  static const String _source = 'GasAuthService';

  final GasApiClient _apiClient;
  final IAuthSessionRepository _sessionRepo;
  final ITokenValidator _tokenValidator;
  bool _isOfflineMode = false;

  GasAuthService({
    GasApiClient? apiClient,
    required IAuthSessionRepository sessionRepository,
    ITokenValidator? tokenValidator,
  }) : _apiClient = apiClient ?? getIt<GasApiClient>(),
       _sessionRepo = sessionRepository,
       _tokenValidator = tokenValidator ?? JwtTokenValidator();

  @override
  bool get isOfflineMode => _isOfflineMode;

  // ============================================================
  // === PUBLIC API ===
  // ============================================================

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    try {
      LogService.info('嘗試註冊: $email', source: _source);

      final response = await _apiClient.post({
        'action': ApiConfig.actionAuthRegister,
        'email': email,
        'password': password,
        'displayName': displayName,
        'avatar': avatar,
      });

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        // Registration requires email verification, don't save session yet
        LogService.info('註冊成功，需驗證 Email', source: _source);

        // Parse user data from response if available
        UserProfile? user;
        if (apiResponse.data['user'] != null) {
          user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        }

        return AuthResult.requiresVerification(errorMessage: '請檢查 Email 完成驗證', user: user);
      } else {
        LogService.warning('註冊失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('註冊例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤，請稍後再試');
    }
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      LogService.info('嘗試登入: $email', source: _source);
      _isOfflineMode = false;

      final response = await _apiClient.post({
        'action': ApiConfig.actionAuthLogin,
        'email': email,
        'password': password,
      });

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);
        final accessToken = apiResponse.data['accessToken'] as String;
        final refreshToken = apiResponse.data['refreshToken'] as String?;

        await _sessionRepo.saveSession(accessToken, user, refreshToken: refreshToken);

        LogService.info('登入成功: ${user.email}', source: _source);
        return AuthResult.success(user: user, accessToken: accessToken, refreshToken: refreshToken);
      } else {
        LogService.warning('登入失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('登入例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤，請稍後再試');
    }
  }

  @override
  Future<AuthResult> loginWithProvider(OAuthProvider provider) async {
    // TODO: Implement OAuth providers in future
    LogService.warning('OAuth login not implemented: $provider', source: _source);
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: 'OAuth 登入尚未實作');
  }

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    try {
      LogService.info('嘗試驗證 Email: $email', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionAuthVerifyEmail, 'email': email, 'code': code});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        LogService.info('Email 驗證成功', source: _source);
        // After verification, user needs to login
        return AuthResult.success(user: null);
      } else {
        LogService.warning('Email 驗證失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('Email 驗證例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤');
    }
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    try {
      LogService.info('嘗試重發驗證碼: $email', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionAuthResendCode, 'email': email});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        LogService.info('驗證碼已發送', source: _source);
        return AuthResult.success(user: null);
      } else {
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e, stackTrace) {
      LogService.error('重發驗證碼例外: $e', source: _source, stackTrace: stackTrace);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤');
    }
  }

  @override
  Future<AuthResult> validateSession() async {
    final token = await _sessionRepo.getAccessToken();
    if (token == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '未登入');
    }

    // Check if token is expiring soon and needs refresh
    if (_tokenValidator.isExpiringSoon(token)) {
      LogService.debug('Token 即將過期，嘗試刷新', source: _source);
      final refreshResult = await refreshToken();
      // If refresh success, return success immediately (new token saved in repo)
      if (refreshResult.isSuccess && refreshResult.accessToken != null) {
        return refreshResult;
      }
      // If refresh fails (e.g. network error, or invalid refresh token), continue to validate current token
      // If current token is still valid, we can use it. If expired, validate API will return error.
      LogService.warning('Token 刷新失敗，繼續驗證舊 Token', source: _source);
    }

    try {
      // Use accessToken in request
      final response = await _apiClient.post({'action': ApiConfig.actionAuthValidate, 'accessToken': token});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);

        // Check if API returned new tokens (e.g. legacy upgrade)
        final newAccessToken = apiResponse.data['accessToken'] as String?;
        final newRefreshToken = apiResponse.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _sessionRepo.saveSession(newAccessToken, user, refreshToken: newRefreshToken);
          return AuthResult.success(user: user, accessToken: newAccessToken, refreshToken: newRefreshToken);
        } else {
          // Update cache user
          // We might want to keep the current tokens if no new ones provided
          await _sessionRepo.saveSession(token, user);
        }

        _isOfflineMode = false;
        return AuthResult.success(user: user, accessToken: token);
      } else {
        // If token expired/invalid, try refresh one last time
        if (apiResponse.code == GasErrorCodes.authAccessTokenExpired) {
          // AUTH_TOKEN_EXPIRED
          final refreshResult = await refreshToken();
          if (refreshResult.isSuccess) {
            return refreshResult;
          }
        }

        await logout();
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e) {
      // Network error -> Check local cache (Offline Support)
      LogService.warning('驗證 Token 失敗 (可能離線): $e', source: _source);
      final cachedUser = await getCachedUserProfile();

      if (cachedUser != null) {
        // Check offline grace period (7 days)
        final validationResult = _tokenValidator.validate(token);
        if (validationResult.payload != null) {
          final tokenAge = DateTime.now().difference(validationResult.payload!.issuedAt);
          if (tokenAge < const Duration(days: 7)) {
            _isOfflineMode = true;
            return AuthResult.success(user: cachedUser, accessToken: token, isOffline: true);
          }
        }
      }

      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '無法連線伺服器');
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    final refreshToken = await _sessionRepo.getRefreshToken();
    if (refreshToken == null) {
      LogService.warning('無 Refresh Token，無法刷新', source: _source);
      return AuthResult.failure(errorCode: 'NO_REFRESH_TOKEN', errorMessage: '無法刷新憑證');
    }

    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionAuthRefreshToken,
        'refreshToken': refreshToken,
      });
      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final newAccessToken = apiResponse.data['accessToken'] as String;
        final user = await _sessionRepo.getUserProfile();

        if (user != null) {
          // Save new access token, keep old refresh token
          await _sessionRepo.saveSession(newAccessToken, user, refreshToken: refreshToken);
          LogService.info('Token 刷新成功', source: _source);
          return AuthResult.success(user: user, accessToken: newAccessToken, refreshToken: refreshToken);
        } else {
          return AuthResult.failure(errorCode: 'USER_NOT_FOUND', errorMessage: '找不到使用者資料');
        }
      } else {
        LogService.warning('刷新 Token 失敗: ${apiResponse.message}', source: _source);
        if (apiResponse.code == GasErrorCodes.authAccessTokenExpired ||
            apiResponse.code == GasErrorCodes.authAccessTokenInvalid) {
          // Refresh token expired or invalid -> logout
          await logout();
        }
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e) {
      LogService.error('刷新 Token 例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤');
    }
  }

  @override
  Future<AuthResult> deleteAccount() async {
    final token = await _sessionRepo.getAccessToken();
    if (token == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '未登入');
    }

    try {
      final response = await _apiClient.post({'action': ApiConfig.actionAuthDeleteUser, 'accessToken': token});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        await logout();
        LogService.info('帳號已刪除', source: _source);
        return AuthResult.success(user: null);
      } else {
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e) {
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤');
    }
  }

  @override
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    final token = await _sessionRepo.getAccessToken();
    if (token == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '未登入');
    }

    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionAuthUpdateProfile,
        'accessToken': token,
        if (displayName != null) 'displayName': displayName,
        if (avatar != null) 'avatar': avatar,
      });

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);

        // Update local session with new user profile
        await _sessionRepo.saveSession(token, user);

        LogService.info('個人資料更新成功: ${user.displayName}', source: _source);
        return AuthResult.success(user: user, accessToken: token);
      } else {
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } catch (e) {
      LogService.error('更新個人資料例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤');
    }
  }

  @override
  Future<void> logout() async {
    await _sessionRepo.clearSession();
    _isOfflineMode = false;
    LogService.info('已登出', source: _source);
  }

  @override
  Future<String?> getAccessToken() => _sessionRepo.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _sessionRepo.getRefreshToken();

  @override
  Future<UserProfile?> getCachedUserProfile() => _sessionRepo.getUserProfile();

  @override
  Future<bool> isLoggedIn() => _sessionRepo.hasSession();
}
