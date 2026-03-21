import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'result.dart';

/// 全域錯誤處理
class AppErrorHandler {
  /// 取得使用者可讀的錯誤訊息
  static String getUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return '發生未預期的錯誤: $error';
  }

  /// 從 DioException 解析出 ApiException (若可解析)
  static ApiException? parseApiException(DioException error) {
    return ApiException.tryParse(error.response?.statusCode, error.response?.data);
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '連線逾時，請檢查網路設定';
      case DioExceptionType.badResponse:
        // 嘗試解析後端結構化錯誤
        final apiError = parseApiException(error);
        if (apiError != null) return apiError.message;

        // fallback: 依 statusCode 回傳通用訊息
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return '授權失敗，請重新登入';
        if (statusCode == 403) return '無權限執行此操作';
        if (statusCode == 404) return '找不到請求的資源';
        if (statusCode != null && statusCode >= 500) return '伺服器內部錯誤 ($statusCode)';
        return '伺服器回應錯誤: $statusCode';
      case DioExceptionType.cancel:
        return '請求已取消';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return '無法連線至伺服器，請檢查網路連線';
        }
        return '發生未知的網路錯誤';
      default:
        return '連線發生錯誤';
    }
  }
}
