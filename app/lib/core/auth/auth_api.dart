import 'package:dio/dio.dart';

import 'auth_state.dart';

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh, required this.expiresIn});
  final String access;
  final String refresh;
  final Duration expiresIn;
}

class AuthSession {
  const AuthSession({required this.tokens, required this.user});
  final AuthTokens tokens;
  final AuthUser user;
}

/// The server answered with an error. [code] is the stable machine-readable code
/// (`invalid_credentials`, `email_not_verified`, `too_many_requests`, ...).
class AuthException implements Exception {
  const AuthException({required this.status, required this.code, this.message = '', this.param});
  final int status;
  final String code;
  final String message;
  final String? param;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'AuthException($status $code): $message';
}

/// The request never completed (offline, timeout).
class AuthNetworkException implements Exception {
  const AuthNetworkException([this.message = 'network error']);
  final String message;
  @override
  String toString() => 'AuthNetworkException: $message';
}

abstract interface class AuthApi {
  /// Creates an account and sends a verification code. No tokens are issued.
  Future<void> register({required String email, required String password, required String displayName, String? avatar});
  Future<AuthSession> verifyEmail({required String email, required String code});
  Future<void> resendVerification(String email);
  Future<AuthSession> login({required String email, required String password});
  Future<AuthTokens> refresh(String refreshToken);
  Future<void> logout(String refreshToken);

  // Authenticated calls (use the Dio with the auth interceptor).
  Future<AuthUser> me();
  Future<AuthUser> updateProfile({String? displayName, String? avatar});
  Future<void> changePassword({required String current, required String next});
  Future<void> deleteAccount();
}

/// [AuthApi] over HTTP.
///
/// [publicDio] has no auth interceptor (register, login, refresh ... must never trigger a refresh);
/// [authedDio] adds the access token and refreshes it on 401.
class DioAuthApi implements AuthApi {
  DioAuthApi({required Dio publicDio, required Dio authedDio}) : _public = publicDio, _authed = authedDio;
  final Dio _public;
  final Dio _authed;

  @override
  Future<void> register({required String email, required String password, required String displayName, String? avatar}) =>
      _call(() => _public.post<Object?>('/auth/register', data: {'email': email, 'password': password, 'display_name': displayName, 'avatar': ?avatar}));

  @override
  Future<AuthSession> verifyEmail({required String email, required String code}) async =>
      _session(await _call(() => _public.post<Object?>('/auth/verify-email', data: {'email': email, 'code': code})));

  @override
  Future<void> resendVerification(String email) => _call(() => _public.post<Object?>('/auth/resend-verification', data: {'email': email}));

  @override
  Future<AuthSession> login({required String email, required String password}) async =>
      _session(await _call(() => _public.post<Object?>('/auth/login', data: {'email': email, 'password': password})));

  @override
  Future<AuthTokens> refresh(String refreshToken) async =>
      _tokens(await _call(() => _public.post<Object?>('/auth/refresh', data: {'refresh_token': refreshToken})));

  @override
  Future<void> logout(String refreshToken) => _call(() => _public.post<Object?>('/auth/logout', data: {'refresh_token': refreshToken}));

  @override
  Future<AuthUser> me() async => _user(await _call(() => _authed.get<Object?>('/auth/me')));

  @override
  Future<AuthUser> updateProfile({String? displayName, String? avatar}) async =>
      _user(await _call(() => _authed.put<Object?>('/auth/me', data: {'display_name': ?displayName, 'avatar': ?avatar})));

  @override
  Future<void> changePassword({required String current, required String next}) =>
      _call(() => _authed.post<Object?>('/auth/change-password', data: {'current_password': current, 'new_password': next}));

  @override
  Future<void> deleteAccount() => _call(() => _authed.delete<Object?>('/auth/me'));

  // ---------------------------------------------------------------- helpers

  Future<Map<String, dynamic>> _call(Future<Response<Object?>> Function() request) async {
    try {
      final res = await request();
      final body = res.data;
      return body is Map<String, dynamic> ? body : const {};
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw AuthNetworkException(e.type.name);
      final data = res.data;
      if (data is Map && data['code'] is String) {
        throw AuthException(status: res.statusCode ?? 0, code: data['code'] as String, message: '${data['message'] ?? ''}', param: data['param'] as String?);
      }
      throw AuthException(status: res.statusCode ?? 0, code: 'http_${res.statusCode}');
    }
  }

  AuthTokens _tokens(Map<String, dynamic> j) =>
      AuthTokens(access: j['access_token'] as String, refresh: j['refresh_token'] as String, expiresIn: Duration(seconds: j['expires_in'] as int));

  AuthUser _user(Map<String, dynamic> j) =>
      AuthUser(id: j['id'] as String, email: j['email'] as String, displayName: j['display_name'] as String, avatar: j['avatar'] as String);

  AuthSession _session(Map<String, dynamic> j) =>
      AuthSession(tokens: _tokens(j['tokens'] as Map<String, dynamic>), user: _user(j['user'] as Map<String, dynamic>));
}
