import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/exceptions/offline_exception.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../tools/log_service.dart';

/// 離線攔截器
///
/// 在每次 API 請求發送前檢查網路連線狀態，
/// 若離線則拋出 [OfflineException]，避免無謂的網路請求。
///
/// 此 Interceptor 取代原有的 [NetworkAwareClient] 包裝層，
/// 以 Dio Interceptor 的方式提供相同的離線保護功能。
@LazySingleton()
class ConnectivityInterceptor extends Interceptor {
  static const String _source = 'ConnectivityInterceptor';
  final IConnectivityService _connectivity;

  ConnectivityInterceptor(this._connectivity);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_connectivity.isOffline) {
      final operation = '${options.method}:${options.path}';
      LogService.debug('攔截離線請求: $operation', source: _source);
      handler.reject(
        DioException(
          requestOptions: options,
          error: OfflineException('目前為離線模式，無法執行此操作', operationName: operation),
          type: DioExceptionType.cancel,
        ),
      );
      return;
    }
    handler.next(options);
  }
}
