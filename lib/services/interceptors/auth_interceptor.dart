import 'package:dio/dio.dart';
import '../../data/repositories/interfaces/i_auth_session_repository.dart';
import '../log_service.dart';

/// Interceptor to handle authentication logic for GAS API
class AuthInterceptor extends Interceptor {
  static const String _source = 'AuthInterceptor';
  final IAuthSessionRepository _sessionRepo;

  AuthInterceptor(this._sessionRepo);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Check if auth should be skipped
    if (options.extra['requiresAuth'] == false) {
      return handler.next(options);
    }
    // Default is to try injecting auth (optional), unless explicitly required
    // which would be handled logic-side, but here we just inject if available.

    // For GAS, we usually send data in POST body (JSON)
    // NOTE: We inject token in Body instead of Header to avoid CORS Preflight (OPTIONS) issues on Web,
    // as GAS Web Apps do not support handling OPTIONS requests.
    if (options.method == 'POST' && options.data is Map<String, dynamic>) {
      try {
        final token = await _sessionRepo.getAccessToken();
        if (token != null && token.isNotEmpty) {
          (options.data as Map<String, dynamic>)['accessToken'] = token;
          LogService.debug('[AuthInterceptor] Injected accessToken', source: _source);
        } else if (options.extra['requiresAuth'] == true) {
          LogService.warning('[AuthInterceptor] Auth required but no token available', source: _source);
          // We could reject here, but letting it fail on server might be better for now
          // unless strict client-side check is desired.
        }
      } catch (e) {
        LogService.error('[AuthInterceptor] Failed to inject token: $e', source: _source);
      }
    }

    handler.next(options);
  }
}
