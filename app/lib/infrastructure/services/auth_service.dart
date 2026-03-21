import '../../core/di.dart';
import '../../core/error/app_error_handler.dart';
import '../../core/exceptions/offline_exception.dart';
import '../../core/offline_config.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../clients/network_aware_client.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../domain/interfaces/i_token_validator.dart';
import 'jwt_token_validator.dart';
import '../tools/log_service.dart';
import 'package:dio/dio.dart';

/// 認證服務
///
/// 實作基於 JWT Token 的身分驗證 [IAuthService]。
class AuthService implements IAuthService {
  static const String _source = 'AuthService';

  final NetworkAwareClient _apiClient;
  final IAuthSessionRepository _sessionRepo;
  final ITokenValidator _tokenValidator;
  bool _isOfflineMode = false;
  String? _currentUserId;
  String? _currentUserEmail;

  /// 建立認證服務實例
  ///
  /// [apiClient] 網路請求客戶端
  /// [sessionRepository] 工作階段儲存倉儲
  /// [tokenValidator] Token 驗證器
  AuthService({
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
        '/auth/register',
        data: {'email': email, 'password': password, 'name': displayName},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        LogService.info('註冊成功', source: _source);

        final data = response.data as Map<String, dynamic>;

        // AuthResponse 回傳 { "token": "...", "user": {...} }
        if (data['user'] != null) {
          final userData = data['user'] as Map<String, dynamic>;
          // Map backend User struct fields to App UserProfile
          final user = UserProfile(
            id: userData['id'] ?? '',
            email: userData['email'] ?? email,
            displayName: userData['name'] ?? displayName,
            avatar: userData['avatar'] ?? avatar ?? '',
          );
          final accessToken = data['token'] as String?;

          if (accessToken != null) {
            await _sessionRepo.saveSession(accessToken, user);
            _currentUserId = user.id;
            _currentUserEmail = user.email;
            return AuthResult.success(user: user, accessToken: accessToken);
          }
          return AuthResult.success(user: user);
        }

        return AuthResult.success(user: null);
      } else {
        // ErrorResponse { "error": "msg" }
        final msg = response.data is Map ? response.data['error'] : 'Unknown Error';
        return AuthResult.failure(errorCode: 'REGISTRATION_FAILED', errorMessage: msg ?? '註冊失敗');
      }
    } on DioException catch (e) {
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'HTTP_ERROR',
        errorMessage: apiError?.message ?? e.message ?? '註冊錯誤',
      );
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

      final response = await _apiClient.post('/auth/login', data: {'email': email, 'password': password});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        if (data['user'] == null || data['token'] == null) {
          return AuthResult.failure(errorCode: 'DATA_ERROR', errorMessage: '伺服器回傳資料異常');
        }

        final userData = data['user'] as Map<String, dynamic>;
        final user = UserProfile(
          id: userData['id'] ?? '',
          email: userData['email'] ?? email,
          displayName: userData['name'] ?? '',
          avatar: userData['avatar'] ?? '',
        );
        final accessToken = data['token'] as String;

        await _sessionRepo.saveSession(accessToken, user);
        _currentUserId = user.id;
        _currentUserEmail = user.email;

        LogService.info('登入成功: ${user.email}', source: _source);
        return AuthResult.success(user: user, accessToken: accessToken);
      } else {
        final msg = response.data is Map ? response.data['error'] : 'Unknown Error';
        return AuthResult.failure(errorCode: 'LOGIN_FAILED', errorMessage: msg ?? '登入失敗');
      }
    } on OfflineException {
      return await _tryOfflineLogin(email);
    } on DioException catch (e) {
      final apiError = AppErrorHandler.parseApiException(e);
      if (apiError != null && apiError.isAuthError) {
        return AuthResult.failure(errorCode: apiError.code, errorMessage: apiError.message);
      }
      return await _tryOfflineLogin(email);
    } catch (e, stackTrace) {
      LogService.error('登入例外: $e', source: _source, stackTrace: stackTrace);
      return await _tryOfflineLogin(email);
    }
  }

  Future<AuthResult> _tryOfflineLogin(String email) async {
    final cachedUser = await getCachedUserProfile();
    final token = await getAccessToken();

    if (cachedUser != null && token != null && cachedUser.email.toLowerCase() == email.toLowerCase()) {
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
          return AuthResult.failure(errorCode: 'OFFLINE_TOKEN_EXPIRED', errorMessage: '離線驗證已過期，請連線後重新登入');
        }
      }
    }
    return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '網路錯誤，無法進行離線登入');
  }

  @override
  Future<AuthResult> loginWithProvider(OAuthProvider provider) async {
    // TODO: 待後端實作第三方登入介面後在此串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '尚未支援 OAuth 登入');
  }

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    // TODO: 待後端實作信箱驗證流程後在此串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '無需Email驗證');
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    // TODO: 待後端實作重新發送驗證碼介面後在此串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '功能尚未開放');
  }

  @override
  Future<AuthResult> validateSession() async {
    final token = await _sessionRepo.getAccessToken();
    if (token == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '未登入');
    }

    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;
        final user = UserProfile(
          id: userData['id'] ?? '',
          email: userData['email'] ?? '',
          displayName: userData['name'] ?? '',
          avatar: userData['avatar'] ?? '',
        );

        await _sessionRepo.saveSession(token, user);
        _currentUserId = user.id;
        _currentUserEmail = user.email;
        _isOfflineMode = false;

        return AuthResult.success(user: user, accessToken: token);
      } else {
        await logout();
        return AuthResult.failure(errorCode: 'SESSION_INVALID', errorMessage: '驗證失敗');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return AuthResult.failure(errorCode: 'UNAUTHORIZED', errorMessage: '授權已過期');
      }

      final cachedUser = await getCachedUserProfile();
      if (cachedUser != null) {
        _isOfflineMode = true;
        _currentUserId = cachedUser.id;
        _currentUserEmail = cachedUser.email;
        return AuthResult.success(user: cachedUser, accessToken: token, isOffline: true);
      }
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '無法連線伺服器');
    } catch (e) {
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '發生錯誤');
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    // TODO: 待後端實作 Refresh Token 機制後在此串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '尚不支援 Refresh Token API');
  }

  @override
  Future<AuthResult> deleteAccount() async {
    // TODO: 目前後端尚未實作註銷帳號介面 (DELETE /auth/me)，待介面完成後在此進行串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '功能開發中');
  }

  @override
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    // TODO: 待後端實作使用者資料更新介面 (PUT /auth/me) 後在此串接
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '功能開發中');
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
