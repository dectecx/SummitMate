import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gas_api_client.dart';
import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';
import 'log_service.dart';

/// 成功代碼
const String kApiCodeSuccess = '0000';

/// Google Sheets API 服務
/// 透過 Google Apps Script 作為 API Gateway
class GoogleSheetsService {
  final GasApiClient _apiClient;

  /// 建構子
  /// [apiClient] - 統一的 GAS API Client (包含 redirect 處理)
  GoogleSheetsService({GasApiClient? apiClient})
    : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 取得所有資料 (行程 + 留言)
  /// 回傳格式：{ code: "0000", data: { itinerary: [...], messages: [...] }, message: "..." }
  /// [tripId] - 可選，篩選特定行程的資料
  Future<FetchAllResult> fetchAll({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchAll${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionFetchAll};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);
      LogService.debug('API 回應: ${response.statusCode}', source: 'API');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // 解析標準化 GAS 回應格式 { code, data, message }
        if (!_isSuccess(json)) {
          return FetchAllResult(success: false, errorMessage: _getErrorMessage(json));
        }

        final data = _getData(json);

        final itineraryList =
            (data['itinerary'] as List<dynamic>?)
                ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final messagesList =
            (data['messages'] as List<dynamic>?)?.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList() ??
            [];

        LogService.debug('解析成功: 行程=${itineraryList.length}, 留言=${messagesList.length}', source: 'API');

        return FetchAllResult(itinerary: itineraryList, messages: messagesList, success: true);
      } else {
        return FetchAllResult(success: false, errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      LogService.error('API 異常: $e', source: 'API');
      return FetchAllResult(success: false, errorMessage: e.toString());
    }
  }

  /// 僅取得行程資料
  /// [tripId] - 可選，篩選特定行程的資料
  Future<FetchAllResult> fetchItinerary({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchItinerary${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionFetchItinerary};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (!_isSuccess(json)) {
          return FetchAllResult(success: false, errorMessage: _getErrorMessage(json));
        }

        final data = _getData(json);
        final itineraryList =
            (data['itinerary'] as List<dynamic>?)
                ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return FetchAllResult(itinerary: itineraryList, success: true);
      } else {
        return FetchAllResult(success: false, errorMessage: 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      return FetchAllResult(success: false, errorMessage: e.toString());
    }
  }

  /// 僅取得留言資料
  /// [tripId] - 可選，篩選特定行程的資料
  Future<FetchAllResult> fetchMessages({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchMessages${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionFetchMessages};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (!_isSuccess(json)) {
          return FetchAllResult(success: false, errorMessage: _getErrorMessage(json));
        }

        final data = _getData(json);
        final messagesList =
            (data['messages'] as List<dynamic>?)?.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList() ??
            [];
        return FetchAllResult(messages: messagesList, success: true);
      } else {
        return FetchAllResult(success: false, errorMessage: 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      return FetchAllResult(success: false, errorMessage: e.toString());
    }
  }

  /// 新增留言
  Future<ApiResult> addMessage(Message message) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionAddMessage, 'data': message.toJson()});
      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 刪除留言
  Future<ApiResult> deleteMessage(String uuid) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionDeleteMessage, 'uuid': uuid});
      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 批次新增留言
  Future<ApiResult> batchAddMessages(List<Message> messages) async {
    try {
      final response = await _apiClient.post({
        'action': 'batch_add_messages',
        'data': messages.map((m) => m.toJson()).toList(),
      });
      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 更新行程 (覆寫雲端)
  Future<ApiResult> updateItinerary(List<ItineraryItem> items) async {
    try {
      final response = await _apiClient.post({
        'action': 'update_itinerary',
        'data': items.map((e) {
          final json = e.toJson();
          // Force est_time to be string in Google Sheets by prepending '
          if (e.estTime.isNotEmpty) {
            json['est_time'] = "'${e.estTime}";
          }
          return json;
        }).toList(),
      });
      return _handleResponse(response);
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 上傳日誌
  Future<ApiResult> uploadLogs(List<LogEntry> logs, {String? deviceName}) async {
    try {
      final response = await _apiClient.post({
        'action': 'upload_logs',
        'logs': logs.map((e) => e.toJson()).toList(),
        'device_info': {
          'device_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'device_name': deviceName ?? 'SummitMate App',
        },
      });

      final result = _handleResponse(response);

      // 解析 GAS 可能回傳的計數 (如果成功)
      if (result.success && response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          final data = _getData(json);
          if (_isSuccess(json) && data['count'] != null) {
            return ApiResult(success: true, message: '已上傳 ${data['count']} 條日誌');
          }
        } catch (_) {} // 忽略解析錯誤，僅回傳成功
      }

      return result;
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  // ============================================================
  // === INTERNAL HELPERS ===
  // ============================================================

  /// 檢查回應是否成功
  /// 支援新格式 { code: "0000" } 和舊格式 { success: true }
  bool _isSuccess(Map<String, dynamic> json) {
    // 新格式: code == "0000"
    if (json.containsKey('code')) {
      return json['code'] == kApiCodeSuccess;
    }
    // 舊格式向後兼容: success == true
    return json['success'] == true;
  }

  /// 取得資料區塊
  /// 支援新格式 { data: {...} } 和舊格式直接包含資料
  Map<String, dynamic> _getData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    // 舊格式向後兼容: 資料直接在 root
    return json;
  }

  /// 取得錯誤訊息
  String _getErrorMessage(Map<String, dynamic> json) {
    // 新格式: message
    if (json.containsKey('message')) {
      return json['message']?.toString() ?? 'Unknown error';
    }
    // 舊格式: error
    return json['error']?.toString() ?? 'Unknown GAS error';
  }

  /// 統一處理回應
  ApiResult _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (_isSuccess(json)) {
          final message = json['message']?.toString();
          return ApiResult(success: true, message: message);
        } else {
          return ApiResult(success: false, errorMessage: _getErrorMessage(json));
        }
      } catch (_) {
        return ApiResult(success: true);
      }
    } else {
      return ApiResult(success: false, errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}

/// 通用 API 結果
class ApiResult {
  final bool success;
  final String? errorMessage;
  final String? message;

  ApiResult({required this.success, this.errorMessage, this.message});
}

/// fetchAll 結果
class FetchAllResult extends ApiResult {
  final List<ItineraryItem> itinerary;
  final List<Message> messages;

  FetchAllResult({this.itinerary = const [], this.messages = const [], required super.success, super.errorMessage});
}
