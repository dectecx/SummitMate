import 'package:dio/dio.dart';
import '../../core/di.dart';
import '../../core/exceptions/offline_exception.dart';
import '../../domain/interfaces/i_api_client.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../tools/log_service.dart';

/// 具網路感知能力的 API Client
///
/// 功能:
/// 1. 在發送任何請求前檢查離線狀態
/// 2. 若離線則拋出 [OfflineException]，避免無謂的網路請求
/// 3. 提供統一的離線錯誤處理機制
///
/// 使用方式:
/// 所有需要打 API 的 Service 應使用此 Client，而非直接使用 basic API Client
class NetworkAwareClient implements IApiClient {
  static const String _source = 'NetworkAwareClient';

  final IApiClient _apiClient;
  final IConnectivityService _connectivity;

  NetworkAwareClient({IApiClient? apiClient, IConnectivityService? connectivity})
    : _apiClient = apiClient ?? getIt<IApiClient>(),
      _connectivity = connectivity ?? getIt<IConnectivityService>();

  /// 檢查是否離線，若是則拋出 [OfflineException]
  void _checkConnectivity(String operation) {
    if (_connectivity.isOffline) {
      LogService.debug('[$_source] 攔截離線請求: $operation', source: _source);
      throw OfflineException('目前為離線模式，無法執行此操作', operationName: operation);
    }
  }

  /// GET 請求 (離線時拋出 OfflineException)
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    _checkConnectivity('GET:$path');
    return await _apiClient.get(path, queryParameters: queryParameters, options: options);
  }

  /// POST 請求 (離線時拋出 OfflineException)
  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    final action = (data is Map) ? data['action'] : 'unknown';
    _checkConnectivity('POST:$action');
    return await _apiClient.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PUT 請求
  @override
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _checkConnectivity('PUT:$path');
    return await _apiClient.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PATCH 請求
  @override
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _checkConnectivity('PATCH:$path');
    return await _apiClient.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// DELETE 請求
  @override
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    _checkConnectivity('DELETE:$path');
    return await _apiClient.delete(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// 釋放資源
  @override
  void dispose() {
    _apiClient.dispose();
  }
}
