import 'package:dio/dio.dart';

/// API Client 介面
///
/// 定義通用的 API 請求方法，以支援未來更換後端實作 (e.g., REST API, GraphQL)。
abstract class IApiClient {
  /// GET 請求
  Future<Response> get({Map<String, String>? queryParams});

  /// POST 請求
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false});

  /// 釋放資源
  void dispose();
}
