import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../domain/interfaces/i_auth_service.dart';

import '../../../data/models/user_profile.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../infrastructure/tools/usage_tracking_service.dart';
import 'auth_state.dart';

/// 管理認證狀態的 Cubit
///
/// 負責協調 [IAuthService] 進行登入/登出，並追蹤使用者狀態。
/// 使用 [UsageTrackingService] 進行行為追蹤。
class AuthCubit extends Cubit<AuthState> {
  static const String _source = 'AuthCubit';

  final IAuthService _authService;
  final UsageTrackingService _usageTrackingService;

  AuthCubit({IAuthService? authService, UsageTrackingService? usageTrackingService})
    : _authService = authService ?? getIt<IAuthService>(),
      _usageTrackingService = usageTrackingService ?? getIt<UsageTrackingService>(),
      super(AuthInitial());

  /// 檢查當前認證狀態 (通常在 App 啟動時呼叫)
  Future<void> checkAuthStatus() async {
    LogService.info('Checking auth status...', source: _source);
    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final cachedUser = await _authService.getCachedUserProfile();
        if (cachedUser != null) {
          _emitAuthenticated(cachedUser, false, isOffline: _authService.isOfflineMode);
          return;
        }
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      LogService.error('Check auth status failed: $e', source: _source);
      emit(const AuthError('無法確認登入狀態'));
    }
  }

  /// 執行註冊
  ///
  /// [email] 使用者 Email
  /// [password] 密碼
  /// [displayName] 顯示名稱
  /// [avatar] 頭像 (可選)
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    LogService.info('Attempting register: $email', source: _source);
    emit(AuthLoading());

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        avatar: avatar,
      );

      if (result.isSuccess) {
        if (result.requiresVerification) {
          emit(AuthRequiresVerification(email));
        } else if (result.user != null) {
          _emitAuthenticated(result.user!, false, isOffline: result.isOffline);
        } else {
          emit(const AuthError('註冊成功但不需驗證且無使用者回傳 (異常)'));
        }
      } else {
        emit(AuthError(result.errorMessage ?? '註冊失敗'));
      }
    } catch (e) {
      LogService.error('Register failed: $e', source: _source);
      emit(AuthError(removeExceptionPrefix(e.toString())));
    }
  }

  /// 執行登入 (Email/Password)
  ///
  /// [email] 使用者 Email
  /// [password] 密碼
  Future<void> login(String email, String password) async {
    LogService.info('Attempting login: $email', source: _source);
    emit(AuthLoading());

    try {
      final result = await _authService.login(email: email, password: password);

      if (result.isSuccess) {
        if (result.user != null) {
          if (result.user!.isVerified) {
            _emitAuthenticated(result.user!, false, isOffline: result.isOffline);
          } else {
            emit(AuthRequiresVerification(email));
          }
        } else {
          emit(const AuthError('登入異常: 無法取得使用者資料'));
        }
      } else {
        emit(AuthError(result.errorMessage ?? '登入失敗'));
      }
    } catch (e) {
      LogService.error('Login failed: $e', source: _source);
      emit(AuthError(removeExceptionPrefix(e.toString())));
    }
  }

  /// 訪客登入
  void loginAsGuest() {
    LogService.info('Login as guest', source: _source);
    // 訪客沒有 UserProfile，手動建構 AuthAuthenticated
    _usageTrackingService.start('訪客', userId: 'guest');
    emit(AuthAuthenticated(userId: 'guest', userName: '訪客', isGuest: true, isOffline: _authService.isOfflineMode));
  }

  /// 驗證 Email
  ///
  /// [email] 使用者 Email
  /// [code] 驗證碼
  Future<void> verifyEmail(String email, String code) async {
    LogService.info('Verifying email: $email', source: _source);
    emit(AuthLoading());

    try {
      final result = await _authService.verifyEmail(email: email, code: code);

      if (result.isSuccess) {
        emit(const AuthOperationSuccess('驗證成功，請登入'));
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError(result.errorMessage ?? '驗證失敗'));
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      LogService.error('Verification failed: $e', source: _source);
      emit(AuthError(removeExceptionPrefix(e.toString())));
      emit(AuthUnauthenticated());
    }
  }

  /// 重發驗證碼
  ///
  /// [email] 使用者 Email
  Future<void> resendCode(String email) async {
    LogService.info('Resending code: $email', source: _source);
    emit(AuthLoading());

    try {
      final result = await _authService.resendVerificationCode(email: email);

      if (result.isSuccess) {
        emit(const AuthOperationSuccess('驗證碼已發送'));
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError(result.errorMessage ?? '發送失敗'));
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      LogService.error('Resend code failed: $e', source: _source);
      emit(AuthError(removeExceptionPrefix(e.toString())));
      emit(AuthUnauthenticated());
    }
  }

  /// 執行登出
  Future<void> logout() async {
    LogService.info('Logging out...', source: _source);
    emit(AuthLoading());

    try {
      // 1. 清除 Auth Session
      await _authService.logout();

      // 2. 停止追蹤
      _usageTrackingService.stop();

      LogService.info('Logout completed (fast transition)', source: _source);
      emit(AuthUnauthenticated());
    } catch (e, stack) {
      LogService.error('Logout failed: $e', source: _source, stackTrace: stack);
      emit(AuthUnauthenticated()); // 即使出錯，UI 也應回到未登入狀態
    }
  }

  /// 更新個人資料
  ///
  /// [displayName] 新增顯示名稱 (可選)
  /// [avatar] 新頭像 URL (可選)
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    LogService.info('Updating profile: $displayName', source: _source);
    try {
      final result = await _authService.updateProfile(displayName: displayName, avatar: avatar);
      if (result.isSuccess && result.user != null) {
        _emitAuthenticated(result.user!, false, isOffline: result.isOffline);
      }
      return result;
    } catch (e) {
      LogService.error('Update profile failed: $e', source: _source);
      return AuthResult.failure(errorCode: 'UPDATE_FAILED', errorMessage: e.toString());
    }
  }

  /// 發送已認證狀態並啟動追蹤
  void _emitAuthenticated(UserProfile user, bool isGuest, {bool isOffline = false}) {
    LogService.info('User authenticated: ${user.id} (${user.displayName})', source: _source);

    // 啟動使用追蹤
    _usageTrackingService.start(user.displayName, userId: user.id);

    emit(
      AuthAuthenticated(
        userId: user.id,
        userName: user.displayName,
        email: user.email,
        avatar: user.avatar,
        roleCode: user.roleCode,
        permissions: user.permissions,
        isGuest: isGuest,
        isOffline: isOffline,
      ),
    );
  }

  /// 移除 Exception 前綴 (UI 顯示用)
  String removeExceptionPrefix(String message) {
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }
}
