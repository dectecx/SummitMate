import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'app_error_codes.dart';
import 'result.dart';

/// 全域錯誤處理
class AppErrorHandler {
  /// 取得使用者可讀的錯誤訊息
  static String getUserMessage(Object error) {
    if (error is ApiException) {
      final codeMessage = getMessageFromCode(error.code);
      if (codeMessage != null) return codeMessage;
      return error.message;
    }

    if (error is AppException) {
      final codeMessage = getMessageFromCode(error.code);
      if (codeMessage != null) return codeMessage;
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
        if (apiError != null) {
          // 優先使用前端定義的對應代碼訊息
          final codeMessage = getMessageFromCode(apiError.code);
          if (codeMessage != null) return codeMessage;

          // 若無對應代碼，則使用後端傳回的原始訊息
          return apiError.message;
        }

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

  /// 依據錯誤代碼取得前端定義的可讀訊息
  static String? getMessageFromCode(String code) {
    switch (code) {
      case AppErrorCodes.invalidCredentials:
        return '帳號或密碼錯誤，請重新輸入';
      case AppErrorCodes.unauthorized:
        return '登入工作階段已過期，請重新登入';
      case AppErrorCodes.emailAlreadyExists:
        return '此 Email 已被其他帳號使用';
      case AppErrorCodes.permissionDenied:
        return '權限不足，無法執行此操作';
      case AppErrorCodes.userNotFound:
        return '找不到該使用者';
      case AppErrorCodes.tokenExpired:
        return '連線逾時，請重新登入';
      case AppErrorCodes.invalidVerificationCode:
        return '驗證碼無效，請確認後再試';
      case AppErrorCodes.verificationCodeExpired:
        return '驗證碼已過期，請重新發送';
      case AppErrorCodes.tripNotFound:
        return '找不到行程資訊';
      case AppErrorCodes.updateConflict:
        return '內容已被更新，請重新整理後再操作';
      case AppErrorCodes.passwordTooShort:
        return '密碼長度太短，至少需要 8 個字元';
      case AppErrorCodes.passwordTooWeak:
        return '密碼強度不足，請包含英文字母與數字';
      case AppErrorCodes.invalidEmail:
        return 'Email 格式不正確';
      case AppErrorCodes.eventNotFound:
        return '活動已不存在';
      default:
        return null;
    }
  }
}
