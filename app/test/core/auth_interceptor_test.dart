import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_api.dart';
import 'package:summitmate/core/auth/auth_interceptor.dart';

import 'auth_support.dart';

void main() {
  late FakeTokenSource tokens;
  late ScriptedAdapter server;
  late Dio dio;
  late String validToken;

  setUp(() {
    tokens = FakeTokenSource(access: 'v1');
    validToken = 'v1';
    server = ScriptedAdapter((req) async {
      if (req.headers['Authorization'] == 'Bearer $validToken') return json({'ok': req.path});
      return json({'code': 'unauthorized', 'message': 'no'}, 401);
    });
    dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = server;
    dio.interceptors.add(AuthInterceptor(tokens: tokens, dio: dio));
  });

  test('adds the access token to requests', () async {
    final res = await dio.get<Map<String, dynamic>>('/things');
    expect(res.data, {'ok': '/things'});
    expect(server.auth, ['Bearer v1']);
    expect(tokens.refreshCalls, 0);
  });

  test('without a token no header is sent', () async {
    tokens.access = null;
    validToken = 'none';
    await expectLater(dio.get<Object?>('/things'), throwsA(isA<DioException>()));
    expect(server.auth.first, isNull);
  });

  test('a 401 refreshes once and replays the request with the new token', () async {
    validToken = 'v2';

    final res = await dio.get<Map<String, dynamic>>('/things');

    expect(res.data, {'ok': '/things'});
    expect(tokens.refreshCalls, 1);
    expect(server.auth, ['Bearer v1', 'Bearer v2']);
  });

  test('many requests failing together trigger a single refresh', () async {
    validToken = 'v2';
    final results = await Future.wait([for (var i = 0; i < 6; i++) dio.get<Map<String, dynamic>>('/r$i')]);
    expect(results.map((r) => r.data!['ok']), ['/r0', '/r1', '/r2', '/r3', '/r4', '/r5']);
    expect(tokens.refreshCalls, 1);
  });

  test('a request that used an outdated token reuses the newer one instead of refreshing again', () async {
    // Another request refreshes while this one is in flight: the 401 for the old token arrives
    // after the current token already changed.
    server = ScriptedAdapter((req) async {
      if (req.headers['Authorization'] == 'Bearer v1') {
        tokens.access = 'v2';
        return json({'code': 'unauthorized'}, 401);
      }
      return json({'ok': req.path});
    });
    dio.httpClientAdapter = server;

    final res = await dio.get<Map<String, dynamic>>('/stale');

    expect(res.data, {'ok': '/stale'});
    expect(tokens.refreshCalls, 0);
    expect(server.auth, ['Bearer v1', 'Bearer v2']);
  });

  test('when the session is over the original 401 reaches the caller', () async {
    validToken = 'v2';
    tokens.refreshFails = true;

    await expectLater(
      dio.get<Object?>('/things'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(tokens.refreshCalls, 1);
    expect(server.requests, hasLength(1), reason: 'no replay without a new token');
  });

  test('a replayed request that still gets 401 is not retried again', () async {
    validToken = 'never-matches';
    await expectLater(dio.get<Object?>('/things'), throwsA(isA<DioException>()));
    expect(tokens.refreshCalls, 1);
    expect(server.requests, hasLength(2));
  });

  test('being offline while refreshing surfaces a connection error, not a lost session', () async {
    validToken = 'v2';
    tokens.refreshOffline = true;
    await expectLater(
      dio.get<Object?>('/things'),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
    );
  });

  test('other errors are passed through untouched', () async {
    server = ScriptedAdapter((req) async => json({'code': 'boom'}, 500));
    dio.httpClientAdapter = server;
    await expectLater(dio.get<Object?>('/x'), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 500)));
    expect(tokens.refreshCalls, 0);
  });

  group('DioAuthApi', () {
    late ScriptedAdapter adapter;
    late DioAuthApi api;

    setUp(() {
      adapter = ScriptedAdapter((req) async => json({'code': 'invalid_credentials', 'message': 'bad', 'param': 'password'}, 401));
      final d = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      api = DioAuthApi(publicDio: d, authedDio: d);
    });

    test('server errors become AuthException with the stable code', () async {
      await expectLater(
        api.login(email: 'a@x.co', password: 'x'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid_credentials').having((e) => e.param, 'param', 'password').having((e) => e.status, 'status', 401)),
      );
    });

    test('responses without our error shape still become AuthException', () async {
      adapter = ScriptedAdapter((req) async => ResponseBody.fromString('<html>', 502));
      final d = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      api = DioAuthApi(publicDio: d, authedDio: d);
      await expectLater(api.login(email: 'a@x.co', password: 'x'), throwsA(isA<AuthException>().having((e) => e.code, 'code', 'http_502')));
    });

    test('connection failures become AuthNetworkException', () async {
      adapter = ScriptedAdapter((req) async => throw DioException.connectionError(requestOptions: req, reason: 'offline'));
      final d = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      api = DioAuthApi(publicDio: d, authedDio: d);
      await expectLater(api.login(email: 'a@x.co', password: 'x'), throwsA(isA<AuthNetworkException>()));
    });

    test('a successful login is parsed into tokens and user', () async {
      adapter = ScriptedAdapter((req) async => json({
        'tokens': {'access_token': 'A', 'refresh_token': 'R', 'expires_in': 900},
        'user': {'id': 'u1', 'email': 'a@x.co', 'display_name': 'Alice', 'avatar': '🐻', 'is_verified': true},
      }));
      final d = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      api = DioAuthApi(publicDio: d, authedDio: d);

      final s = await api.login(email: 'a@x.co', password: 'x');

      expect([s.tokens.access, s.tokens.refresh, s.tokens.expiresIn, s.user.displayName], ['A', 'R', const Duration(minutes: 15), 'Alice']);
      expect(adapter.requests.single.data, {'email': 'a@x.co', 'password': 'x'});
    });
  });
}
