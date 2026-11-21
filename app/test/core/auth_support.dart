import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:summitmate/core/auth/auth_api.dart';
import 'package:summitmate/core/auth/auth_interceptor.dart';
import 'package:summitmate/core/auth/auth_state.dart';

class FakeAccount {
  FakeAccount(this.user, this.password, {this.verified = false});
  final AuthUser user;
  String password;
  bool verified;
}

/// In-memory server for the auth endpoints.
class FakeAuthApi implements AuthApi {
  final Map<String, FakeAccount> accounts = {};
  int _n = 0;
  int refreshCalls = 0;
  int loginCalls = 0;
  final List<String> logoutTokens = [];
  final List<String> refreshTokensSeen = [];

  Object? refreshError;
  Object? logoutError;
  Completer<void>? refreshGate;
  String lastCode = '123456';

  AuthTokens _tokens() {
    _n++;
    return AuthTokens(access: 'access-$_n', refresh: 'refresh-$_n', expiresIn: const Duration(minutes: 15));
  }

  AuthUser addAccount(String email, String password, {String name = 'Name', bool verified = true}) {
    final user = AuthUser(id: 'id-${email.split('@').first}', email: email, displayName: name, avatar: '🐻');
    accounts[email] = FakeAccount(user, password, verified: verified);
    return user;
  }

  FakeAccount _need(String email) => accounts[email] ?? (throw const AuthException(status: 401, code: 'invalid_credentials'));

  @override
  Future<void> register({required String email, required String password, required String displayName, String? avatar}) async {
    if (accounts[email]?.verified ?? false) throw const AuthException(status: 409, code: 'email_already_exists');
    addAccount(email, password, name: displayName, verified: false);
  }

  @override
  Future<AuthSession> verifyEmail({required String email, required String code}) async {
    if (code != lastCode) throw const AuthException(status: 400, code: 'invalid_verification_code');
    final a = _need(email)..verified = true;
    return AuthSession(tokens: _tokens(), user: a.user);
  }

  @override
  Future<void> resendVerification(String email) async {}

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    loginCalls++;
    final a = accounts[email];
    if (a == null || a.password != password) throw const AuthException(status: 401, code: 'invalid_credentials');
    if (!a.verified) throw const AuthException(status: 403, code: 'email_not_verified');
    return AuthSession(tokens: _tokens(), user: a.user);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls++;
    refreshTokensSeen.add(refreshToken);
    await refreshGate?.future;
    final err = refreshError;
    if (err != null) throw err;
    return _tokens();
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutTokens.add(refreshToken);
    final err = logoutError;
    if (err != null) throw err;
  }

  @override
  Future<AuthUser> me() async => throw UnimplementedError();

  AuthUser? profileOverride;
  @override
  Future<AuthUser> updateProfile({String? displayName, String? avatar}) async {
    final old = accounts.values.first.user;
    final updated = AuthUser(id: old.id, email: old.email, displayName: displayName ?? old.displayName, avatar: avatar ?? old.avatar);
    profileOverride = updated;
    return updated;
  }

  final List<String> passwordChanges = [];
  @override
  Future<void> changePassword({required String current, required String next}) async {
    final a = accounts.values.first;
    if (a.password != current) throw const AuthException(status: 400, code: 'wrong_current_password');
    passwordChanges.add(next);
    a.password = next;
  }

  bool deleted = false;
  @override
  Future<void> deleteAccount() async => deleted = true;
}

/// A Dio adapter that answers from a function, so tests need no network.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  /// The Authorization header each request carried when it was sent (RequestOptions are mutated on replay).
  final List<String?> auth = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    auth.add(options.headers['Authorization'] as String?);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

/// A [TokenSource] holding one access token that "refreshes" by bumping a counter.
class FakeTokenSource implements TokenSource {
  FakeTokenSource({this.access = 'v1'});
  String? access;
  int refreshCalls = 0;
  bool refreshFails = false;
  bool refreshOffline = false;
  Future<String?>? _inFlight;

  @override
  Future<String?> accessToken() async => access;

  @override
  Future<String?> refreshAccessToken() => _inFlight ??= () async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (refreshOffline) throw const AuthNetworkException();
    if (refreshFails) return null;
    return access = 'v${refreshCalls + 1}';
  }().whenComplete(() => _inFlight = null);
}
