import 'package:dio/dio.dart';
import '../core/di.dart';
import '../core/exceptions/offline_exception.dart';
import 'interfaces/i_connectivity_service.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 具網路感知能力的 API Client
///
/// 功能:
/// 1. 在發送任何請求前檢查離線狀態
/// 2. 若離線則拋出 [OfflineException]，避免無謂的網路請求
/// 3. 提供統一的離線錯誤處理機制
///
/// 使用方式:
/// 所有需要打 API 的 Service 應使用此 Client，而非直接使用 GasApiClient
class NetworkAwareClient {
  static const String _source = 'NetworkAwareClient';

  final GasApiClient _apiClient;
  final IConnectivityService _connectivity;

  NetworkAwareClient({GasApiClient? apiClient, IConnectivityService? connectivity})
    : _apiClient = apiClient ?? getIt<GasApiClient>(),
      _connectivity = connectivity ?? getIt<IConnectivityService>();

  /// 檢查是否離線，若是則拋出 [OfflineException]
  void _checkConnectivity(String operation) {
    if (_connectivity.isOffline) {
      LogService.debug('[$_source] 攔截離線請求: $operation', source: _source);
      throw OfflineException('目前為離線模式，無法執行此操作', operationName: operation);
    }
  }

  /// GET 請求 (離線時拋出 OfflineException)
  Future<Response> get({Map<String, String>? queryParams}) async {
    _checkConnectivity('GET');
    return await _apiClient.get(queryParams: queryParams);
  }

  /// POST 請求 (離線時拋出 OfflineException)
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    final action = body['action']?.toString() ?? 'unknown';
    _checkConnectivity('POST:$action');
    return await _apiClient.post(body, requiresAuth: requiresAuth);
  }

  /// 判斷目前是否離線 (供 Service 快速查詢用)
  bool get isOffline => _connectivity.isOffline;

  /// 判斷目前是否線上 (供 Service 快速查詢用)
  bool get isOnline => !_connectivity.isOffline;

  /// 釋放資源
  void dispose() {
    _apiClient.dispose();
  }
}
