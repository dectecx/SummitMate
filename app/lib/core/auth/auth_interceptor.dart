import 'package:dio/dio.dart';

import 'auth_api.dart';

/// What the interceptor needs from the auth layer.
abstract interface class TokenSource {
  Future<String?> accessToken();
  Future<String?> refreshAccessToken();
}

/// Adds the access token to requests and, on 401, refreshes it once and retries.
///
/// Many requests failing at the same time share a single refresh (the [TokenSource] guarantees
/// that). If the session is over, the original 401 is passed on and the caller sees it.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokens, required this.dio});

  final TokenSource tokens;

  /// The Dio this interceptor is installed on, used to replay the request.
  final Dio dio;

  static const _retried = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokens.accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 || req.extra[_retried] == true) return handler.next(err);

    final used = _bearer(req.headers['Authorization']);
    try {
      // Someone else may have refreshed already; only refresh if the token we used is still current.
      var token = await tokens.accessToken();
      if (token == null || token == used) token = await tokens.refreshAccessToken();
      if (token == null) return handler.next(err);

      req.extra[_retried] = true;
      req.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await dio.fetch<Object?>(req));
    } on AuthNetworkException catch (e) {
      handler.next(DioException(requestOptions: req, type: DioExceptionType.connectionError, error: e));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  static String? _bearer(Object? header) => header is String && header.startsWith('Bearer ') ? header.substring(7) : null;
}
