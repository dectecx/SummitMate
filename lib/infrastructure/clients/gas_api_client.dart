import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../tools/log_service.dart';

import '../../domain/interfaces/i_api_client.dart';

/// Google Apps Script API 用戶端
/// 處理重新導向 (302)、Web 相容性等通用邏輯
class GasApiClient implements IApiClient {
  static const String _source = 'GasApiClient';

  final Dio _dio;
  final String _baseUrl;

  GasApiClient({Dio? dio, required String baseUrl}) : _dio = dio ?? Dio(), _baseUrl = baseUrl;

  /// GET 請求
  @override
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

  /// POST 請求 (自動處理重新導向)
  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    final stopwatch = Stopwatch()..start();
    final action = body['action'] ?? 'unknown';

    try {
      // [Web 相容性]
      // Web: 使用 text/plain 避免 CORS Preflight (OPTIONS)，因 GAS 不支援。
      final options = Options(
        contentType: kIsWeb ? 'text/plain' : 'application/json',
        extra: {'requiresAuth': requiresAuth},
        // 我們需要手動處理 302 重導向，因為 GAS 常回傳 HTML body 重導向
        followRedirects: !kIsWeb,
        validateStatus: (status) => status != null && status < 500,
      );

      final jsonBody = jsonEncode(body);
      LogService.debug('[POST] 請求開始: action=$action', source: _source);
      LogService.debug('[POST] Request Body: $jsonBody', source: _source);

      // Warning: Dio 會根據 contentType 自動編碼。
      // 若為 'text/plain'，必須傳送字串。若為 'application/json'，可傳送 Map。
      // 但為了避免 Dio 的自動 JSON 邏輯影響 GAS，這裡統一處裡。
      // 實際上 GAS 的 doPost(e) 可以正確處裡 JSON 文字 payload。
      final data = kIsWeb ? jsonBody : body;

      final response = await _dio.post(_baseUrl, data: data, options: options);

      // [Mobile 相容性]
      // 1. 標準 302 重導向 (若 followRedirects 為 true，Dio 會自動處理，
      //    但我們可能需要針對 GAS 的特定行為進行手動重導向邏輯)
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

      // 2. HTML Body 重導向 (GAS 常見)
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
      // 確保 data 為 Map 以保持一致性
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

  @override
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
