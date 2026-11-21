import 'package:summitmate/core/error/app_error.dart';
import 'result.dart';

/// 對應後端 error.type 分類
enum ApiErrorType {
  validationError,
  authError,
  businessLogicError,
  invalidRequestError,
  serverError,
  unknown;

  static ApiErrorType fromString(String value) {
    return switch (value) {
      'validation_error' => ApiErrorType.validationError,
      'auth_error' => ApiErrorType.authError,
      'business_logic_error' => ApiErrorType.businessLogicError,
      'invalid_request_error' => ApiErrorType.invalidRequestError,
      'server_error' => ApiErrorType.serverError,
      _ => ApiErrorType.unknown,
    };
  }
}

/// 後端標準化錯誤回應的 Dart 對應
class ApiException extends AppException {
  final ApiErrorType type;
  final String? param;
  final int statusCode;

  const ApiException({
    required this.type,
    required String code,
    required String message,
    this.param,
    required this.statusCode,
  }) : super(message, code: code);

  /// 建立從 AppError 轉換的實例
  factory ApiException.fromAppError(int statusCode, AppError error) {
    return ApiException(
      type: ApiErrorType.fromString(error.type),
      code: error.code,
      message: error.message,
      param: error.param,
      statusCode: statusCode,
    );
  }

  /// 嘗試從 response body 解析，後端格式為 {"error": {"type": "...", ...}}
  static ApiException? tryParse(int? statusCode, dynamic data) {
    if (statusCode == null || data is! Map<String, dynamic>) return null;

    if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
      final appError = AppError.fromJson(data['error'] as Map<String, dynamic>);
      return ApiException.fromAppError(statusCode, appError);
    }

    return null;
  }

  bool get isAuthError => type == ApiErrorType.authError;
  bool get isValidationError => type == ApiErrorType.validationError;
  bool get isBusinessLogicError => type == ApiErrorType.businessLogicError;
}
