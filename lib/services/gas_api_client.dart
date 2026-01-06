import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'log_service.dart';

/// Client related to Google Apps Script API calls
/// Handles common logic like Redirects (302), Web compatibility, etc.
class GasApiClient {
  static const String _source = 'GasApiClient';

  final Dio _dio;
  final String _baseUrl;

  GasApiClient({Dio? dio, required String baseUrl}) : _dio = dio ?? Dio(), _baseUrl = baseUrl;

  /// GET request
  Future<Response> get({Map<String, String>? queryParams}) async {
    final stopwatch = Stopwatch()..start();
    try {
      LogService.debug('[GET] 請求開始: $_baseUrl', source: _source);

      final response = await _dio.get(_baseUrl, queryParameters: queryParams);

      stopwatch.stop();
      LogService.info('[GET] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      LogService.debug('[GET] Response Body: ${response.data}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[GET] 失敗 (${stopwatch.elapsedMilliseconds}ms): $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// POST request with automated redirect handling
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    final stopwatch = Stopwatch()..start();
    final action = body['action'] ?? 'unknown';

    try {
      // [Web Compatibility]
      // Web: Use text/plain to avoid CORS Preflight (OPTIONS) which GAS doesn't support.
      final options = Options(
        contentType: kIsWeb ? 'text/plain' : 'application/json',
        extra: {'requiresAuth': requiresAuth},
        // We need to handle 302 manually for HTML body redirects common in GAS
        followRedirects: !kIsWeb,
        validateStatus: (status) => status != null && status < 500,
      );

      final jsonBody = jsonEncode(body);
      LogService.debug('[POST] 請求開始: action=$action', source: _source);
      LogService.debug('[POST] Request Body: $jsonBody', source: _source);

      // Warning: Dio automatically encodes based on contentType.
      // If 'text/plain', we must send string. If 'application/json', we can send Map.
      // But here we might want to consistently send string to avoid Dio's auto-json logic messing with GAS?
      // Actually GAS handles JSON text payload fine in doPost(e).
      final data = kIsWeb ? jsonBody : body;

      final response = await _dio.post(_baseUrl, data: data, options: options);

      // [Mobile Compatibility]
      // 1. Standard 302 Redirect (Dio handles this automatically if followRedirects is true,
      //    but we might have manual redirect logic desire for specific GAS behavior)
      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          LogService.debug('[POST] 追蹤 302 重導向', source: _source);
          final redirectResponse = await _dio.get(location);
          stopwatch.stop();
          LogService.info(
            '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${redirectResponse.statusCode}',
            source: _source,
          );
          return redirectResponse;
        }
      }

      // 2. HTML Body Redirect (Common in GAS)
      if (response.data is String &&
          response.data.toString().contains('<HTML>') &&
          (response.data.toString().contains('HREF=') || response.data.toString().contains('href='))) {
        final hrefMatch = RegExp(r'HREF="([^"]+)"', caseSensitive: false).firstMatch(response.data.toString());
        if (hrefMatch != null) {
          final redirectUrl = hrefMatch.group(1)!.replaceAll('&amp;', '&');
          LogService.debug('[POST] 追蹤 HTML 重導向', source: _source);
          final redirectResponse = await _dio.get(redirectUrl);
          stopwatch.stop();
          LogService.info(
            '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${redirectResponse.statusCode}',
            source: _source,
          );
          LogService.debug('[POST] Response Body: ${redirectResponse.data}', source: _source);
          return redirectResponse;
        }
      }

      stopwatch.stop();
      // Ensure data is Map for consistency
      if (response.data is String) {
        try {
          response.data = jsonDecode(response.data);
        } catch (e) {
          LogService.warning('[POST] JSON 解析失敗 (可能為非標準回應): $e', source: _source);
        }
      }

      LogService.info(
        '[POST] 完成 ($action, ${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}',
        source: _source,
      );
      LogService.debug('[POST] Response Body: ${response.data}', source: _source);
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
    _dio.close();
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

  /// 從 Map 建立
  factory GasApiResponse.fromJson(Map<String, dynamic> json) {
    return GasApiResponse(json);
  }

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
