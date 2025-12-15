import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';

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
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        final itineraryList = (json['itinerary'] as List<dynamic>?)
            ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

        final messagesList = (json['messages'] as List<dynamic>?)
            ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

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
    } catch (e) {
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
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': ApiConfig.actionAddMessage,
          'data': message.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return ApiResult(success: true);
      } else {
        return ApiResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
    }
  }

  /// 刪除留言
  Future<ApiResult> deleteMessage(String uuid) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': ApiConfig.actionDeleteMessage,
          'uuid': uuid,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResult(success: true);
      } else {
        return ApiResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResult(success: false, errorMessage: e.toString());
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
