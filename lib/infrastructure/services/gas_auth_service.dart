import '../../core/constants.dart';
import '../../core/constants/gas_error_codes.dart';
import '../../core/di.dart';
import '../../core/exceptions/offline_exception.dart';
import '../../core/offline_config.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../clients/gas_api_client.dart';
import '../clients/network_aware_client.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../domain/interfaces/i_token_validator.dart';
import 'jwt_token_validator.dart';
import '../tools/log_service.dart';

/// GAS (Google Apps Script) 認證服務
/// 實作基於 JWT Token 的 GAS 後端認證 [IAuthService]。
/// 可透過 DI 替換為 FirebaseAuthService 等其他實作。
class GasAuthService implements IAuthService {
  static const String _source = 'GasAuthService';

  final NetworkAwareClient _apiClient;
  final IAuthSessionRepository _sessionRepo;
  final ITokenValidator _tokenValidator;
  bool _isOfflineMode = false;
  String? _currentUserId;
  String? _currentUserEmail;

  GasAuthService({
    NetworkAwareClient? apiClient,
    required IAuthSessionRepository sessionRepository,
    ITokenValidator? tokenValidator,
  }) : _apiClient = apiClient ?? getIt<NetworkAwareClient>(),
       _sessionRepo = sessionRepository,
       _tokenValidator = tokenValidator ?? JwtTokenValidator();

  @override
  bool get isOfflineMode => _isOfflineMode;

  @override
  String? get currentUserId => _currentUserId;

  @override
  String? get currentUserEmail => _currentUserEmail;

  // ============================================================
  // === 公開 API (Public API) ===
  // ============================================================

  /// 註冊新帳號
  ///
  /// [email] 使用者 Email
  /// [password] 密碼
  /// [displayName] 顯示名稱
  /// [avatar] 頭像 URL (可選)
  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    try {
      LogService.info('嘗試註冊: $email', source: _source);

      final response = await _apiClient.post(
        '',
        data: {
          'action': ApiConfig.actionAuthRegister,
          'email': email,
          'password': password,
          'displayName': displayName,
          'avatar': avatar,
        },
      );

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        // 註冊需要驗證 Email，尚不儲存 Session
        LogService.info('註冊成功，需驗證 Email', source: _source);

        // 若回應包含使用者資料則解析
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

  /// 登入
  ///
  /// [email] 使用者 Email
  /// [password] 密碼
  @override
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      LogService.info('嘗試登入: $email', source: _source);
      _isOfflineMode = false;

      final response = await _apiClient.post(
        '',
        data: {'action': ApiConfig.actionAuthLogin, 'email': email, 'password': password},
      );

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final data = apiResponse.data;
        Map<String, dynamic>? userData = data['user'] as Map<String, dynamic>?;
        if (userData == null) {
          LogService.error('登入成功但缺少使用者資料', source: _source);
          return AuthResult.failure(errorCode: 'DATA_ERROR', errorMessage: '伺服器回傳資料異常');
        }

        // [Role] Inject permissions from root response into user map
        if (data['permissions'] != null) {
          userData['permissions'] = data['permissions'];
        }
        // Also ensure role info is present if passed separately (though api_auth.gs puts it in user too)
        if (data['role'] != null) {
          // Optional: store full role object if needed, but UserProfile uses code/id
        }

        final user = UserProfile.fromJson(userData);
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;

        await _sessionRepo.saveSession(accessToken, user, refreshToken: refreshToken);
        _currentUserId = user.id;
        _currentUserEmail = user.email;

        LogService.info('登入成功: ${user.email}', source: _source);
        return AuthResult.success(user: user, accessToken: accessToken, refreshToken: refreshToken);
      } else {
        LogService.warning('登入失敗: ${apiResponse.message}', source: _source);
        return AuthResult.failure(errorCode: apiResponse.code, errorMessage: apiResponse.message);
      }
    } on OfflineException {
      // NetworkAwareClient 攔截到離線請求，嘗試使用快取登入
      LogService.info('離線模式偵測，嘗試使用快取登入', source: _source);
      return await _tryOfflineLogin(email);
    } catch (e, stackTrace) {
      LogService.error('登入例外: $e', source: _source, stackTrace: stackTrace);
      // 其他網路錯誤也嘗試離線登入
      return await _tryOfflineLogin(email);
    }
  }

  /// 離線登入嘗試
  /// 當網路不可用時，檢查本地快取的 session 是否與請求的 email 匹配
  ///
  /// [email] 嘗試登入的 Email
  Future<AuthResult> _tryOfflineLogin(String email) async {
    final cachedUser = await getCachedUserProfile();
    final token = await getAccessToken();

    if (cachedUser != null && token != null && cachedUser.email.toLowerCase() == email.toLowerCase()) {
      // 驗證 Token 時效 (離線寬限期)
      final validationResult = _tokenValidator.validate(token);
      if (validationResult.payload != null) {
        final tokenAge = DateTime.now().difference(validationResult.payload!.issuedAt);
        if (tokenAge < OfflineConfig.offlineGracePeriod) {
          LogService.info('離線登入成功: $email', source: _source);
          _isOfflineMode = true;
          _currentUserId = cachedUser.id;
          _currentUserEmail = cachedUser.email;
          return AuthResult.success(user: cachedUser, accessToken: token, isOffline: true);
        } else {
          LogService.warning('離線登入失敗: Token 已超過 ${OfflineConfig.offlineGracePeriodDays} 天', source: _source);
          return AuthResult.failure(errorCode: 'OFFLINE_TOKEN_EXPIRED', errorMessage: '離線驗證已過期，請連線後重新登入');
        }
      }
    }

    // 無匹配的快取 Session
    return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤，請稍後再試');
  }

  @override
  Future<AuthResult> loginWithProvider(OAuthProvider provider) async {
    // TODO: 未來實作 OAuth Provider
    LogService.warning('OAuth login not implemented: $provider', source: _source);
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: 'OAuth 登入尚未實作');
  }

  /// 驗證 Email
  ///
  /// [email] 使用者 Email
  /// [code] 驗證碼
  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    try {
      LogService.info('嘗試驗證 Email: $email', source: _source);

      final response = await _apiClient.post(
        '',
        data: {'action': ApiConfig.actionAuthVerifyEmail, 'email': email, 'code': code},
      );

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        LogService.info('Email 驗證成功', source: _source);
        // 驗證後需要使用者重新登入
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

  /// 重發驗證碼
  ///
  /// [email] 目標 Email
  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    try {
      LogService.info('嘗試重發驗證碼: $email', source: _source);

      final response = await _apiClient.post('', data: {'action': ApiConfig.actionAuthResendCode, 'email': email});

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

  /// 驗證目前 Session 是否有效
  /// 若 Token 即將過期會嘗試自動刷新
  @override
  Future<AuthResult> validateSession() async {
    final token = await _sessionRepo.getAccessToken();
    if (token == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '未登入');
    }

    // 檢查 Token 是否即將過期並需要刷新
    if (_tokenValidator.isExpiringSoon(token)) {
      LogService.debug('Token 即將過期，嘗試刷新', source: _source);
      final refreshResult = await refreshToken();
      // 若刷新成功，立即回傳成功結果 (Repository 已更新)
      if (refreshResult.isSuccess && refreshResult.accessToken != null) {
        return refreshResult;
      }
      // 若刷新失敗 (例如網路錯誤或 Refresh Token 無效)，繼續驗證舊 Token
      // 若舊 Token 仍有效則繼續使用。若已過期，API 驗證將會回傳錯誤。
      LogService.warning('Token 刷新失敗，繼續驗證舊 Token', source: _source);
    }

    try {
      // 使用 Access Token 發送請求
      final response = await _apiClient.post('', data: {'action': ApiConfig.actionAuthValidate, 'accessToken': token});

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final userData = apiResponse.data['user'] as Map<String, dynamic>?;
        if (userData == null) {
          LogService.error('驗證成功但缺少使用者資料', source: _source);
          return AuthResult.failure(errorCode: 'DATA_ERROR', errorMessage: '伺服器回傳資料異常');
        }
        final user = UserProfile.fromJson(userData);

        // 檢查 API 是否回傳新 Token (例如舊版升級)
        final newAccessToken = apiResponse.data['accessToken'] as String?;
        final newRefreshToken = apiResponse.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _sessionRepo.saveSession(newAccessToken, user, refreshToken: newRefreshToken);
          _currentUserId = user.id;
          _currentUserEmail = user.email;
          return AuthResult.success(user: user, accessToken: newAccessToken, refreshToken: newRefreshToken);
        } else {
          // 更新快取的使用者資料
          // 若無新 Token 則保持原樣
          await _sessionRepo.saveSession(token, user);
          _currentUserId = user.id;
          _currentUserEmail = user.email;
        }

        _isOfflineMode = false;
        return AuthResult.success(user: user, accessToken: token);
      } else {
        // 若 Token 過期/無效，嘗試最後一次刷新
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
      // 網路錯誤 -> 檢查本地快取 (離線支援)
      LogService.warning('驗證 Token 失敗 (可能離線): $e', source: _source);
      final cachedUser = await getCachedUserProfile();

      if (cachedUser != null) {
        // 檢查離線寬限期
        final validationResult = _tokenValidator.validate(token);
        if (validationResult.payload != null) {
          final tokenAge = DateTime.now().difference(validationResult.payload!.issuedAt);
          if (tokenAge < OfflineConfig.offlineGracePeriod) {
            _isOfflineMode = true;
            _currentUserId = cachedUser.id;
            _currentUserEmail = cachedUser.email;
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
      final response = await _apiClient.post(
        '',
        data: {'action': ApiConfig.actionAuthRefreshToken, 'refreshToken': refreshToken},
      );
      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final newAccessToken = apiResponse.data['accessToken'] as String;
        final user = await _sessionRepo.getUserProfile();

        if (user != null) {
          // 儲存新 Access Token，保留舊 Refresh Token
          await _sessionRepo.saveSession(newAccessToken, user, refreshToken: refreshToken);
          _currentUserId = user.id;
          _currentUserEmail = user.email;
          LogService.info('Token 刷新成功', source: _source);
          return AuthResult.success(user: user, accessToken: newAccessToken, refreshToken: refreshToken);
        } else {
          return AuthResult.failure(errorCode: 'USER_NOT_FOUND', errorMessage: '找不到使用者資料');
        }
      } else {
        LogService.warning('刷新 Token 失敗: ${apiResponse.message}', source: _source);
        if (apiResponse.code == GasErrorCodes.authAccessTokenExpired ||
            apiResponse.code == GasErrorCodes.authAccessTokenInvalid) {
          // Refresh Token 過期或無效 -> 登出
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
      final response = await _apiClient.post(
        '',
        data: {'action': ApiConfig.actionAuthDeleteUser, 'accessToken': token},
      );

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        await logout();
        _currentUserId = null;
        _currentUserEmail = null;
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
      final response = await _apiClient.post(
        '',
        data: {
          'action': ApiConfig.actionAuthUpdateProfile,
          'accessToken': token,
          if (displayName != null) 'displayName': displayName,
          if (avatar != null) 'avatar': avatar,
        },
      );

      final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

      if (apiResponse.isSuccess) {
        final user = UserProfile.fromJson(apiResponse.data['user'] as Map<String, dynamic>);

        // 更新本地 Session 中的使用者資料
        await _sessionRepo.saveSession(token, user);
        _currentUserId = user.id;
        _currentUserEmail = user.email;

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
    _currentUserId = null;
    _currentUserEmail = null;
    LogService.info('已登出', source: _source);
  }

  @override
  Future<String?> getAccessToken() => _sessionRepo.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _sessionRepo.getRefreshToken();

  @override
  Future<UserProfile?> getCachedUserProfile() async {
    final user = await _sessionRepo.getUserProfile();
    if (user != null) {
      _currentUserId ??= user.id;
      _currentUserEmail ??= user.email;
    }
    return user;
  }

  @override
  Future<bool> isLoggedIn() async {
    final hasSession = await _sessionRepo.hasSession();
    if (hasSession && (_currentUserEmail == null || _currentUserId == null)) {
      final user = await _sessionRepo.getUserProfile();
      _currentUserId = user?.id;
      _currentUserEmail = user?.email;
    }
    return hasSession;
  }
}
