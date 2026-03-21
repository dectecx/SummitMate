import 'package:dio/dio.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../tools/log_service.dart';

/// 用於處理 API 認證邏輯的攔截器 (Interceptor)
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
      LogService.warning('[AuthInterceptor] 401 Unauthorized detected. Triggering logout.', source: _source);

      // 此處目前的權宜之計是直接清除 Session。
      // 未來若有 Refresh Token，應在此嘗試換發 Token。
      await _sessionRepo.clearSession();

      // 注意：此處僅清除資料，UI 層的跳轉通常由 AuthCubit 監聽狀態或全域攔截處理。
    }

    return handler.next(err);
  }
}
