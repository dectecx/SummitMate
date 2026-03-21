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
///
/// 解析 `{"error": {"type": "...", "code": "...", "message": "...", "param": "..."}}`
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

  /// 從 HTTP response body 解析
  ///
  /// [statusCode] HTTP 狀態碼
  /// [body] response.data (Map)
  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>? ?? {};
    return ApiException(
      type: ApiErrorType.fromString(error['type'] as String? ?? ''),
      code: error['code'] as String? ?? 'unknown',
      message: error['message'] as String? ?? '發生未知錯誤',
      param: error['param'] as String?,
      statusCode: statusCode,
    );
  }

  /// 嘗試從 response body 解析，解析失敗回傳 null
  static ApiException? tryParse(int? statusCode, dynamic data) {
    if (statusCode == null || data is! Map<String, dynamic>) return null;
    if (data['error'] is! Map<String, dynamic>) return null;
    return ApiException.fromResponse(statusCode, data);
  }

  bool get isAuthError => type == ApiErrorType.authError;
  bool get isValidationError => type == ApiErrorType.validationError;
  bool get isBusinessLogicError => type == ApiErrorType.businessLogicError;
}
