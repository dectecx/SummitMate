import 'package:dio/dio.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../tools/log_service.dart';

/// 用於處理 GAS API 認證邏輯的攔截器 (Interceptor)
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
    // 預設行為是嘗試注入認證資訊 (可選)，除非明確被要求跳過
    // 真正的邏輯應由 Service 端確保需要認證，但這裡若有 Token 則盡量注入。

    // 對於 GAS，我們通常將資料放在 POST Body (JSON) 中
    // 注意：我們將 Token 注入 Body 而非 Header，以避免 Web 上的 CORS Preflight (OPTIONS) 問題，
    // 因為 GAS Web Apps 不支援處理 OPTIONS 請求。
    if (options.method == 'POST' && options.data is Map<String, dynamic>) {
      try {
        final token = await _sessionRepo.getAccessToken();
        if (token != null && token.isNotEmpty) {
          (options.data as Map<String, dynamic>)['accessToken'] = token;
          LogService.debug('[AuthInterceptor] Injected accessToken', source: _source);
        } else if (options.extra['requiresAuth'] == true) {
          LogService.warning('[AuthInterceptor] Auth required but no token available', source: _source);
          // 這裡可以選擇阻擋請求，但暫時讓伺服器端回傳失敗可能更好
          // 除非前端希望有嚴格檢查。
        }
      } catch (e) {
        LogService.error('[AuthInterceptor] Failed to inject token: $e', source: _source);
      }
    }

    handler.next(options);
  }
}
