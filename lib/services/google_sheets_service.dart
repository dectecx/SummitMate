import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';
import 'log_service.dart';

/// Google Sheets API 服務
/// 透過 Google Apps Script 作為 API Gateway
class GoogleSheetsService {
  final http.Client _client;
  final String _baseUrl;

  /// 建構子
  /// [client] - HTTP 客戶端 (用於測試時注入 Mock)
  /// [baseUrl] - Google Apps Script Web App URL
  GoogleSheetsService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? EnvConfig.gasBaseUrl;

  /// 取得所有資料 (行程 + 留言)
  /// 回傳格式：{ itinerary: [...], messages: [...] }
  Future<FetchAllResult> fetchAll() async {
    try {
      final uri = Uri.parse('$_baseUrl?action=${ApiConfig.actionFetchAll}');
      debugPrint('🌐 API 請求: $uri');
      debugPrint('🌐 baseUrl: $_baseUrl (isEmpty: ${_baseUrl.isEmpty})');

      if (_baseUrl.isEmpty) {
        return FetchAllResult(
          success: false,
          errorMessage: 'GAS_BASE_URL 未設定。請確認 .env.dev 檔案已正確配置。',
        );
      }

      final response = await _client.get(uri);
      debugPrint('🌐 API 回應: ${response.statusCode}');
      debugPrint('🌐 回應內容: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        final itineraryList = (json['itinerary'] as List<dynamic>?)
            ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

        final messagesList = (json['messages'] as List<dynamic>?)
            ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

        debugPrint('🌐 解析成功: 行程=${itineraryList.length}, 留言=${messagesList.length}');

        return FetchAllResult(
          itinerary: itineraryList,
          messages: messagesList,
          success: true,
        );
      } else {
        return FetchAllResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e, stack) {
      debugPrint('🌐 API 異常: $e');
      debugPrint('🌐 堆疊: $stack');
      return FetchAllResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 新增留言
  Future<ApiResult> addMessage(Message message) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _postWithRedirect(
        uri,
        {
          'action': ApiConfig.actionAddMessage,
          'data': message.toJson(),
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 刪除留言
  Future<ApiResult> deleteMessage(String uuid) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _postWithRedirect(
        uri,
        {
          'action': ApiConfig.actionDeleteMessage,
          'uuid': uuid,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 批次新增留言
  Future<ApiResult> batchAddMessages(List<Message> messages) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _postWithRedirect(
        uri,
        {
          'action': 'batch_add_messages',
          'data': messages.map((m) => m.toJson()).toList(),
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 更新行程 (覆寫雲端)
  Future<ApiResult> updateItinerary(List<ItineraryItem> items) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _postWithRedirect(
        uri,
        {
          'action': 'update_itinerary',
          'data': items.map((e) {
            final json = e.toJson();
            // Force est_time to be string in Google Sheets by prepending '
            if (e.estTime.isNotEmpty) {
              json['est_time'] = "'${e.estTime}";
            }
            return json;
          }).toList(),
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 上傳日誌
  Future<ApiResult> uploadLogs(List<LogEntry> logs, {String? deviceName}) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _postWithRedirect(
        uri,
        {
          'action': 'upload_logs',
          'logs': logs.map((e) => e.toJson()).toList(),
          'device_info': {
            'device_id': DateTime.now().millisecondsSinceEpoch.toString(),
            'device_name': deviceName ?? 'SummitMate App',
          },
        },
      );

      final result = _handleResponse(response);

      // 解析 GAS 可能回傳的計數 (如果成功)
      if (result.success && response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          if (json['success'] == true && json['count'] != null) {
            return ApiResult(success: true, errorMessage: '已上傳 ${json['count']} 條日誌');
          }
        } catch (_) {} // 忽略解析錯誤，僅回傳成功
      }

      return result;
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 處理 POST 請求 (自動處理 Redirect)
  Future<http.Response> _postWithRedirect(Uri uri, Map<String, dynamic> body) async {
    // [Web Compatibility]
    // Web: Use text/plain to avoid CORS Preflight (OPTIONS) which GAS doesn't support.
    // GAS parses e.postData.contents regardless of Content-Type.
    final headers = {
      'Content-Type': kIsWeb ? 'text/plain' : 'application/json',
    };

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    // [Web Compatibility]
    // Web: Browser follows redirects automatically. We just return the response.
    if (kIsWeb) {
      return response;
    }

    // [Mobile Compatibility]
    // Manual handling of GAS 302 Redirect (http package limitation on mobile)
    if (response.statusCode == 302) {
      final location = response.headers['location'];
      if (location != null && location.isNotEmpty) {
        debugPrint('🌐 轉導至: $location');
        return await _client.get(Uri.parse(location));
      }
    }

    return response;
  }

  /// 統一處理回應
  ApiResult _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return ApiResult(success: true);
    } else {
      return ApiResult(
        success: false,
        errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  /// 關閉 HTTP 客戶端
  void dispose() {
    _client.close();
  }
}

/// 通用 API 結果
class ApiResult {
  final bool success;
  final String? errorMessage;

  ApiResult({required this.success, this.errorMessage});
}

/// fetchAll 結果
class FetchAllResult extends ApiResult {
  final List<ItineraryItem> itinerary;
  final List<Message> messages;

  FetchAllResult({
    this.itinerary = const [],
    this.messages = const [],
    required super.success,
    super.errorMessage,
  });
}
