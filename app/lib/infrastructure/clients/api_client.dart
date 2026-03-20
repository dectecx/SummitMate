import 'package:dio/dio.dart';
import '../../domain/interfaces/i_api_client.dart';
import '../tools/log_service.dart';

/// API 用戶端
///
/// 作為與身分驗證伺服器溝通的底層介面實作 [IApiClient]。
class ApiClient implements IApiClient {
  static const String _source = 'ApiClient';

  final Dio _dio;
  final String _baseUrl;

  /// 建立 API 用戶端實例
  ///
  /// [dio] Dio 客戶端實例
  /// [baseUrl] API 基礎 URL
  ApiClient({Dio? dio, required String baseUrl}) : _dio = dio ?? Dio(), _baseUrl = baseUrl;

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final url = '$_baseUrl$path';
      LogService.debug('[GET] 請求開始: $url', source: _source);

      // 替換為標準 GET
      final response = await _dio.get(url, queryParameters: queryParameters, options: options);

      stopwatch.stop();
      LogService.info('[GET] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[GET] 失敗: $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final url = '$_baseUrl$path';
      LogService.debug('[POST] 請求開始: $url', source: _source);

      final response = await _dio.post(url, data: data, queryParameters: queryParameters, options: options);

      stopwatch.stop();
      LogService.info('[POST] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[POST] 失敗: $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final url = '$_baseUrl$path';
      LogService.debug('[PUT] 請求開始: $url', source: _source);

      final response = await _dio.put(url, data: data, queryParameters: queryParameters, options: options);

      stopwatch.stop();
      LogService.info('[PUT] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[PUT] 失敗: $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final url = '$_baseUrl$path';
      LogService.debug('[PATCH] 請求開始: $url', source: _source);

      final response = await _dio.patch(url, data: data, queryParameters: queryParameters, options: options);

      stopwatch.stop();
      LogService.info('[PATCH] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[PATCH] 失敗: $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final url = '$_baseUrl$path';
      LogService.debug('[DELETE] 請求開始: $url', source: _source);

      final response = await _dio.delete(url, data: data, queryParameters: queryParameters, options: options);

      stopwatch.stop();
      LogService.info('[DELETE] 完成 (${stopwatch.elapsedMilliseconds}ms) HTTP ${response.statusCode}', source: _source);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      LogService.error('[DELETE] 失敗: $e', source: _source, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _dio.close();
  }
}
