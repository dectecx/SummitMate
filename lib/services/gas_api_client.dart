import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'log_service.dart';

/// Callback type for getting the current auth token
typedef AuthTokenProvider = Future<String?> Function();

/// Client related to Google Apps Script API calls
/// Handles common logic like Redirects (302), Web compatibility, etc.
class GasApiClient {
  static const String _source = 'GasApiClient';

  final http.Client _client;
  final String _baseUrl;

  /// Optional callback to get the current auth token for authenticated requests
  AuthTokenProvider? authTokenProvider;

  GasApiClient({http.Client? client, required String baseUrl, this.authTokenProvider})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl;

  /// GET request
  Future<http.Response> get({Map<String, String>? queryParams}) async {
    final stopwatch = Stopwatch()..start();
    try {
      Uri uri = Uri.parse(_baseUrl);
      if (queryParams != null && queryParams.isNotEmpty) {
        final newParams = Map<String, String>.from(uri.queryParameters);
        newParams.addAll(queryParams);
        uri = uri.replace(queryParameters: newParams);
      }

      LogService.debug('[GET] 請求開始: $uri', source: _source);
      final response = await _client.get(uri);
      stopwatch.stop();

      LogService.info('[GET] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      // 詳細 Response Log
      LogService.debug('[GET] Response Body: ${response.body}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[GET] 失敗 (${stopwatch.elapsedMilliseconds}ms): $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// POST request with automated redirect handling
  /// Automatically injects authToken if authTokenProvider is set
  Future<http.Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    final stopwatch = Stopwatch()..start();
    final action = body['action'] ?? 'unknown';

    try {
      final uri = Uri.parse(_baseUrl);
      // [Web Compatibility]
      // Web: Use text/plain to avoid CORS Preflight (OPTIONS) which GAS doesn't support.
      final headers = {'Content-Type': kIsWeb ? 'text/plain' : 'application/json'};

      // Inject auth token if provider is available and user is logged in
      final requestBody = Map<String, dynamic>.from(body);
      if (authTokenProvider != null) {
        final token = await authTokenProvider!();
        if (token != null && token.isNotEmpty) {
          requestBody['authToken'] = token;
          LogService.debug('[POST] Auth token injected', source: _source);
        } else if (requiresAuth) {
          LogService.warning('[POST] Auth required but no token available', source: _source);
        }
      }

      final jsonBody = jsonEncode(requestBody);
      LogService.debug('[POST] 請求開始: action=$action', source: _source);
      // 詳細 Request Log
      LogService.debug('[POST] Request Body: $jsonBody', source: _source);

      final response = await _client.post(uri, headers: headers, body: jsonBody);

      // [Web Compatibility] Browser follows redirects automatically.
      if (kIsWeb) {
        stopwatch.stop();
        LogService.info(
          '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}',
          source: _source,
        );
        LogService.debug('[POST] Response Body: ${response.body}', source: _source);
        return response;
      }

      // [Mobile Compatibility]
      // 1. Standard 302 Redirect
      if (response.statusCode == 302) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          LogService.debug('[POST] 追蹤 302 重導向', source: _source);
          final redirectResponse = await _client.get(Uri.parse(location));
          stopwatch.stop();
          LogService.info(
            '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${redirectResponse.statusCode}',
            source: _source,
          );
          LogService.debug('[POST] Response Body: ${redirectResponse.body}', source: _source);
          return redirectResponse;
        }
      }

      // 2. HTML Body Redirect (Common in GAS)
      if (response.body.contains('<HTML>') && (response.body.contains('HREF=') || response.body.contains('href='))) {
        final hrefMatch = RegExp(r'HREF="([^"]+)"', caseSensitive: false).firstMatch(response.body);
        if (hrefMatch != null) {
          final redirectUrl = hrefMatch.group(1)!.replaceAll('&amp;', '&');
          LogService.debug('[POST] 追蹤 HTML 重導向', source: _source);
          final redirectResponse = await _client.get(Uri.parse(redirectUrl));
          stopwatch.stop();
          LogService.info(
            '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${redirectResponse.statusCode}',
            source: _source,
          );
          LogService.debug('[POST] Response Body: ${redirectResponse.body}', source: _source);
          return redirectResponse;
        }
      }

      stopwatch.stop();
      LogService.info(
        '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}',
        source: _source,
      );
      LogService.debug('[POST] Response Body: ${response.body}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error(
        '[POST] 失敗 ($action, ${stopwatch.elapsedMilliseconds}ms): $e',
        source: _source,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// 成功代碼常數
const String kGasCodeSuccess = '0000';

/// GAS API 回應解析器
///
/// 格式: { code: "0000", data: {...}, message: "..." }
class GasApiResponse {
  final Map<String, dynamic> _json;

  GasApiResponse(this._json);

  /// 從 JSON 字串建立
  factory GasApiResponse.fromJsonString(String jsonString) {
    return GasApiResponse(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// 回應是否成功 (code == "0000")
  bool get isSuccess => _json['code'] == kGasCodeSuccess;

  /// 取得資料區塊
  Map<String, dynamic> get data {
    final dataField = _json['data'];
    if (dataField is Map<String, dynamic>) {
      return dataField;
    }
    return {};
  }

  /// 取得訊息
  String get message => _json['message']?.toString() ?? '';

  /// 取得錯誤代碼
  String get code => _json['code']?.toString() ?? '';

  /// 取得原始 JSON
  Map<String, dynamic> get raw => _json;
}
