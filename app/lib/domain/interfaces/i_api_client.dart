import 'package:dio/dio.dart';

/// API Client 介面
///
/// 定義通用的 API 請求方法，以支援未來更換後端實作 (e.g., REST API, GraphQL)。
abstract interface class IApiClient {
  /// GET 請求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options});

  /// POST 請求
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});

  /// PUT 請求
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});

  /// PATCH 請求
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});

  /// DELETE 請求
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options});

  /// 釋放資源
  void dispose();
}
