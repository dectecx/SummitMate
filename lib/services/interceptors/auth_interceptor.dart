import 'package:dio/dio.dart';
import '../interfaces/i_auth_token_provider.dart';
import '../log_service.dart';

/// Interceptor to handle authentication logic for GAS API
class AuthInterceptor extends Interceptor {
  static const String _source = 'AuthInterceptor';
  final IAuthTokenProvider _tokenProvider;

  AuthInterceptor(this._tokenProvider);

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
        final token = await _tokenProvider.getAuthToken();
        if (token != null && token.isNotEmpty) {
          (options.data as Map<String, dynamic>)['authToken'] = token;
          LogService.debug('[AuthInterceptor] Injected authToken', source: _source);
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
