import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:summitmate/core/di/injection.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../tools/log_service.dart';

/// 用於處理 API 認證邏輯的攔截器 (Interceptor)
@LazySingleton()
class AuthInterceptor extends Interceptor {
  static const String _source = 'AuthInterceptor';
  final IAuthSessionRepository _sessionRepo;

  AuthInterceptor(this._sessionRepo);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 檢查是否需要跳過認證
    if (options.extra['requiresAuth'] == false) {
      return handler.next(options);
    }

    // 注入認證資訊 (Authorization: Bearer <token>)
    try {
      final token = await _sessionRepo.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        LogService.debug('[AuthInterceptor] Injected Authorization Header', source: _source);
      } else if (options.extra['requiresAuth'] == true) {
        LogService.warning('[AuthInterceptor] Auth required but no token available', source: _source);
        // TODO: 伺服器端會回傳 401，此處暫不做阻斷以便測試
      }
    } catch (e) {
      LogService.error('[AuthInterceptor] Failed to inject token: $e', source: _source);
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 處理 401 Unauthorized 錯誤
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // 避免無限迴圈：若本身是 refresh 或 login 介面 401，直接清除 Session 並回傳錯誤
      if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
        LogService.warning('[AuthInterceptor] 401 on auth endpoint ($path). Triggering logout.', source: _source);
        await _sessionRepo.clearSession();
        return handler.next(err);
      }

      LogService.warning('[AuthInterceptor] 401 Unauthorized detected. Attempting to refresh token.', source: _source);

      try {
        // 使用 getIt 獲取 IAuthService 避免循環依賴
        final authService = getIt<IAuthService>();
        final result = await authService.refreshToken();

        if (result.isSuccess && result.accessToken != null) {
          LogService.info(
            '[AuthInterceptor] Token refreshed successfully. Retrying original request.',
            source: _source,
          );

          // 更新原始請求的 Authorization header
          err.requestOptions.headers['Authorization'] = 'Bearer ${result.accessToken}';

          // 使用 getIt 取得現有的 Dio 實例重新發送請求
          final dio = getIt<Dio>();
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } else {
          LogService.warning('[AuthInterceptor] Refresh token failed. Triggering logout.', source: _source);
          await _sessionRepo.clearSession();
        }
      } catch (e) {
        LogService.error('[AuthInterceptor] Refresh token exception: $e', source: _source);
        await _sessionRepo.clearSession();
      }
    }

    return handler.next(err);
  }
}
