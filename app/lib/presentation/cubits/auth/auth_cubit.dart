import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_error_handler.dart';
import 'package:summitmate/domain/domain.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';

import 'auth_state.dart';

/// 管理認證狀態的 Cubit
///
/// 負責協調 [IAuthService] 進行登入/登出，並追蹤使用者狀態。
/// 使用 [UsageTrackingService] 進行行為追蹤。
@injectable
class AuthCubit extends Cubit<AuthState> {
  static const String _source = 'AuthCubit';

  final IAuthService _authService;
  final UsageTrackingService _usageTrackingService;
  StreamSubscription<UserProfile?>? _authSubscription;

  AuthCubit(this._authService, this._usageTrackingService) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.onAuthStateChanged.listen((user) {
      if (user != null) {
        _emitAuthenticated(user, false, isOffline: _authService.isOfflineMode);
      } else {
        // 只有在當前是已登入狀態，且 service 說 null 時才發送 (避免覆蓋其他狀態如 AuthLoading)
        if (state is AuthAuthenticated) {
          _usageTrackingService.stop();
          emit(AuthUnauthenticated());
        } else if (state is AuthInitial) {
          emit(AuthUnauthenticated());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  /// 檢查當前認證狀態 (通常在 App 啟動時呼叫)
  Future<void> checkAuthStatus() async {
    LogService.info('Checking auth status...', source: _source);
    // 透過 validateSession 觸發 Stream 更新
    try {
      await _authService.validateSession();
    } catch (e) {
      LogService.error('Check auth status failed: $e', source: _source);
      // 如果 validateSession 失敗，且當前不是 AuthError 狀態，則發送 AuthError
      // 避免覆蓋 AuthLoading 等狀態
      if (state is! AuthError) {
        emit(const AuthError('無法確認登入狀態'));
      }
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
        }
        // 成功路徑會經由 Stream 自動發送 AuthAuthenticated
      } else {
        emit(AuthError(result.errorMessage ?? '註冊失敗'));
      }
    } catch (e) {
      LogService.error('Register failed: $e', source: _source);
      emit(AuthError(AppErrorHandler.getUserMessage(e)));
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
        if (result.user != null && !result.user!.isVerified) {
          emit(AuthRequiresVerification(email));
        }
        // 成功路徑會經由 Stream 自動發送 AuthAuthenticated
      } else {
        emit(AuthError(result.errorMessage ?? '登入失敗'));
      }
    } catch (e) {
      LogService.error('Login failed: $e', source: _source);
      emit(AuthError(AppErrorHandler.getUserMessage(e)));
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
      emit(AuthError(AppErrorHandler.getUserMessage(e)));
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
      emit(AuthError(AppErrorHandler.getUserMessage(e)));
      emit(AuthUnauthenticated());
    }
  }

  /// 執行登出
  Future<void> logout() async {
    LogService.info('Logging out...', source: _source);
    emit(AuthLoading());

    try {
      await _authService.logout();
      // 成功路徑會經由 Stream 自動發送 AuthUnauthenticated
    } catch (e, stack) {
      LogService.error('Logout failed: $e', source: _source, stackTrace: stack);
      emit(AuthUnauthenticated()); // 保底
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
      // 成功路徑會經由 Stream 自動發送 AuthAuthenticated
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
        role: user.role,
        permissions: user.permissions,
        isGuest: isGuest,
        isOffline: isOffline,
      ),
    );
  }
}
