import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/map/rudy/rudy_client.dart';
import 'package:summitmate/features/map/rudy/rudy_constants.dart';
import 'package:summitmate/features/map/rudy/rudy_models.dart';

typedef _Handler = ResponseBody Function(RequestOptions o);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _res(int code, {Map<String, String> headers = const {}, List<RedirectRecord>? redirects}) => ResponseBody(
  const Stream<Uint8List>.empty(),
  code,
  headers: {
    for (final e in headers.entries) e.key: [e.value],
  },
  redirects: redirects,
);

(RudyClient, _FakeAdapter) _make(_Handler h) {
  final adapter = _FakeAdapter(h);
  final dio = Dio()..httpClientAdapter = adapter;
  return (RudyClient(dio, appVersion: '1.2.3', contactUrl: 'https://example.com/c'), adapter);
}

RudyRemoteFile _file({String? lm = 'Thu, 19 Nov 2026 07:21:00 GMT', int? len = 100, String host = 'a.example'}) =>
    RudyRemoteFile(name: 'x', resolvedUrl: Uri.parse('https://$host/x'), lastModified: lm, contentLength: len);

void main() {
  test('user agent format', () {
    expect(
      rudyUserAgent(appVersion: '1.2.3', contactUrl: 'https://example.com/c'),
      'SummitMate/1.2.3 (+https://example.com/c)',
    );
  });

  test('probe success: one HEAD with UA, parses headers', () async {
    final (client, adapter) = _make(
      (_) => _res(
        200,
        headers: {
          'content-length': '325046194',
          'last-modified': 'Thu, 19 Nov 2026 07:21:00 GMT',
          'accept-ranges': 'bytes',
        },
      ),
    );
    final p = await client.probe(rudyPmtilesFile);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.method, 'HEAD');
    expect(adapter.requests.single.uri.toString(), '$rudyDownloadBase$rudyPmtilesFile');
    expect(adapter.requests.single.headers['User-Agent'], 'SummitMate/1.2.3 (+https://example.com/c)');
    expect(p.availability, RudyAvailability.available);
    expect(p.file!.contentLength, 325046194);
    expect(p.file!.lastModified, 'Thu, 19 Nov 2026 07:21:00 GMT');
    expect(p.file!.acceptsRanges, isTrue);
  });

  test('redirect: resolved URL is the mirror URL', () async {
    final mirror = Uri.parse('https://moi.kcwu.csie.org/v1/a.zip');
    final (client, _) = _make((_) => _res(200, redirects: [RedirectRecord(302, 'HEAD', mirror)]));
    final p = await client.probe('a.zip');
    expect(p.file!.resolvedUrl, mirror);
    expect(p.file!.acceptsRanges, isFalse);
    expect(p.file!.contentLength, isNull);
  });

  test('404 and 410 map to notAvailable', () async {
    for (final code in [404, 410]) {
      final (client, _) = _make((_) => _res(code));
      final p = await client.probe(rudyPmtilesFile);
      expect(p.availability, RudyAvailability.notAvailable);
      expect(p.file, isNull);
    }
  });

  test('5xx and connection errors map to unreachable without throwing', () async {
    final (c1, _) = _make((_) => _res(503));
    expect((await c1.probe('a')).availability, RudyAvailability.unreachable);
    final (c2, _) = _make((o) => throw DioException.connectionError(requestOptions: o, reason: 'offline'));
    final p = await c2.probe('a');
    expect(p.availability, RudyAvailability.unreachable);
    expect(p.file, isNull);
  });

  group('fingerprint and needsUpdate', () {
    final (client, _) = _make((_) => _res(200));

    test('stable and includes host', () {
      expect(_file().fingerprint, _file().fingerprint);
      expect(_file().fingerprint, 'Thu, 19 Nov 2026 07:21:00 GMT|100|a.example');
      expect(_file(host: 'b.example').fingerprint, isNot(_file().fingerprint));
    });

    test('needsUpdate cases', () {
      final f = _file();
      expect(client.needsUpdate(null, f), isTrue);
      expect(client.needsUpdate(f.fingerprint, f), isFalse);
      expect(client.needsUpdate(f.fingerprint, _file(len: 101)), isTrue);
      expect(client.needsUpdate(f.fingerprint, _file(lm: 'other')), isTrue);
    });

    test('downloadHeaders has only User-Agent', () {
      expect(client.downloadHeaders(), {'User-Agent': 'SummitMate/1.2.3 (+https://example.com/c)'});
    });
  });

  test('attribution has required elements', () {
    for (final s in [
      '魯地圖',
      'https://rudymap.tw',
      'OpenStreetMap contributors',
      'ODbL',
      '內政部',
      'DTM',
      'OpenAndroMaps Elevate',
      'Tobias Kühn',
    ]) {
      expect(rudyAttribution, contains(s));
    }
  });
}
