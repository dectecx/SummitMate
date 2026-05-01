import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../core/di/injection.dart';
import '../../core/error/app_error_handler.dart';
import '../../core/exceptions/offline_exception.dart';
import '../../core/offline_config.dart';
import '../clients/network_aware_client.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/domain/interfaces/i_token_validator.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'jwt_token_validator.dart';
import '../tools/log_service.dart';
import 'package:dio/dio.dart';

/// 認證服務
///
/// 實作基於 JWT Token 的身分驗證 [IAuthService]。
@LazySingleton(as: IAuthService)
class AuthService implements IAuthService {
  static const String _source = 'AuthService';

  final NetworkAwareClient _apiClient;
  final IAuthSessionRepository _sessionRepo;
  final ITokenValidator _tokenValidator;
  bool _isOfflineMode = false;
  String? _currentUserId;
  String? _currentUserEmail;
  final _authStateController = StreamController<UserProfile?>.broadcast();

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
       _tokenValidator = tokenValidator ?? JwtTokenValidator() {
    // 初始載入快取狀態
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    final user = await getCachedUserProfile();
    if (user != null) {
      _currentUserId = user.id;
      _currentUserEmail = user.email;
      _authStateController.add(user);
    } else {
      _authStateController.add(null);
    }
  }

  void _notifyAuthState(UserProfile? user) {
    _currentUserId = user?.id;
    _currentUserEmail = user?.email;
    _authStateController.add(user);
  }

  @override
  Stream<UserProfile?> get onAuthStateChanged => _authStateController.stream;

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
        data: {'email': email, 'password': password, 'display_name': displayName},
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
            displayName: userData['display_name'] ?? displayName,
            avatar: userData['avatar'] ?? avatar ?? '',
          );
          final accessToken = data['token'] as String?;
          final refreshToken = data['refresh_token'] as String?;

          if (accessToken != null) {
            await _sessionRepo.saveSession(accessToken, user, refreshToken: refreshToken);
            _notifyAuthState(user);
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
          displayName: userData['display_name'] ?? '',
          avatar: userData['avatar'] ?? '',
        );
        final accessToken = data['token'] as String;
        final refreshToken = data['refresh_token'] as String?;

        await _sessionRepo.saveSession(accessToken, user, refreshToken: refreshToken);
        _notifyAuthState(user);

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
          _notifyAuthState(cachedUser);
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
    // TODO: 待與需求方確認 OAuth 串接項目 (例如: LINE? Google? Apple?) 及對應的後端介面設計
    // 目前尚未規劃具體流程，因此先回傳未實作。請勿在尚未確認需求前擅自開發。
    LogService.info('嘗試第三方登入: ${provider.name} (尚未實作)', source: _source);
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: 'OAuth 登入尚未確認需求與實作');
  }

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    // TODO: 待後端實作 SMTP 或其他發信驗證邏輯後，再正式串接。目前後端僅開啟了介面 (Stub)，尚未實作內容。
    try {
      final response = await _apiClient.post('/auth/verify-email', data: {'email': email, 'code': code});

      if (response.statusCode == 200) {
        return AuthResult.success();
      }
      return AuthResult.failure(errorCode: 'VERIFICATION_FAILED', errorMessage: '信箱驗證失敗');
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '後端尚未實作此功能');
      }
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'NETWORK_ERROR',
        errorMessage: apiError?.message ?? '連線失敗',
      );
    } catch (e) {
      LogService.error('信箱驗證例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'UNKNOWN_ERROR', errorMessage: '系統錯誤');
    }
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    // TODO: 待後端實作 SMTP 或其他發信驗證邏輯後，再正式串接。目前後端僅開啟了介面 (Stub)，尚未實作內容。
    try {
      final response = await _apiClient.post('/auth/resend-verification', data: {'email': email});

      if (response.statusCode == 200) {
        return AuthResult.success();
      }
      return AuthResult.failure(errorCode: 'RESEND_FAILED', errorMessage: '重發驗證碼失敗');
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: '後端尚未實作此功能');
      }
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'NETWORK_ERROR',
        errorMessage: apiError?.message ?? '連線失敗',
      );
    } catch (e) {
      LogService.error('重發驗證碼例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'UNKNOWN_ERROR', errorMessage: '系統錯誤');
    }
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
          displayName: userData['display_name'] ?? '',
          avatar: userData['avatar'] ?? '',
        );

        await _sessionRepo.saveSession(token, user);
        _notifyAuthState(user);
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
        _notifyAuthState(cachedUser);
        return AuthResult.success(user: cachedUser, accessToken: token, isOffline: true);
      }
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '無法連線伺服器');
    } catch (e) {
      return AuthResult.failure(errorCode: 'NETWORK_ERROR', errorMessage: '發生錯誤');
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    final currentRefreshToken = await getRefreshToken();
    if (currentRefreshToken == null) {
      return AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '無 Refresh Token');
    }

    try {
      final response = await _apiClient.post('/auth/refresh', data: {'refresh_token': currentRefreshToken});

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (newAccessToken != null && userData != null) {
          final user = UserProfile(
            id: userData['id'] ?? '',
            email: userData['email'] ?? '',
            displayName: userData['display_name'] ?? '',
            avatar: userData['avatar'] ?? '',
          );
          await _sessionRepo.saveSession(newAccessToken, user, refreshToken: newRefreshToken);
          _notifyAuthState(user);
          return AuthResult.success(user: user, accessToken: newAccessToken);
        }
      }

      await logout();
      return AuthResult.failure(errorCode: 'REFRESH_FAILED', errorMessage: 'Token 刷新失敗');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        await logout();
        return AuthResult.failure(errorCode: 'REFRESH_EXPIRED', errorMessage: '授權已過期');
      }
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'NETWORK_ERROR',
        errorMessage: apiError?.message ?? '連線失敗',
      );
    } catch (e) {
      LogService.error('Refresh Token 例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'UNKNOWN_ERROR', errorMessage: '系統錯誤');
    }
  }

  @override
  Future<AuthResult> deleteAccount() async {
    try {
      final response = await _apiClient.delete('/auth/me');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await logout();
        return AuthResult.success();
      }
      return AuthResult.failure(errorCode: 'DELETE_FAILED', errorMessage: '註銷帳號失敗');
    } on DioException catch (e) {
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'NETWORK_ERROR',
        errorMessage: apiError?.message ?? '連線失敗',
      );
    } catch (e) {
      LogService.error('註銷帳號例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'UNKNOWN_ERROR', errorMessage: '系統錯誤');
    }
  }

  @override
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (avatar != null) data['avatar'] = avatar;

      if (data.isEmpty) return AuthResult.success();

      final response = await _apiClient.put('/auth/me', data: data);

      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;

        // Update cached profile
        final oldUser = await getCachedUserProfile();
        if (oldUser != null) {
          final newUser = UserProfile(
            id: oldUser.id,
            email: oldUser.email,
            displayName: userData['display_name'] ?? oldUser.displayName,
            avatar: userData['avatar'] ?? oldUser.avatar,
          );
          final token = await getAccessToken();
          if (token != null) {
            await _sessionRepo.saveSession(token, newUser);
          }
          _notifyAuthState(newUser);
          return AuthResult.success(user: newUser, accessToken: token);
        }
        return AuthResult.success();
      }
      return AuthResult.failure(errorCode: 'UPDATE_FAILED', errorMessage: '更新資料失敗');
    } on DioException catch (e) {
      final apiError = AppErrorHandler.parseApiException(e);
      return AuthResult.failure(
        errorCode: apiError?.code ?? 'NETWORK_ERROR',
        errorMessage: apiError?.message ?? '連線失敗',
      );
    } catch (e) {
      LogService.error('更新資料例外: $e', source: _source);
      return AuthResult.failure(errorCode: 'UNKNOWN_ERROR', errorMessage: '系統錯誤');
    }
  }

  @override
  Future<void> logout() async {
    await _sessionRepo.clearSession();
    _isOfflineMode = false;
    _notifyAuthState(null);
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
