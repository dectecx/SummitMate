/// 應用程式常見錯誤代碼常數
/// 用於前端業務邏輯判斷，應對齊後端定義的錯誤代碼。
class AppErrorCodes {
  // Auth Related
  static const String authInvalidCredentials = 'auth_invalid_credentials';
  static const String authUnauthorized = 'auth_unauthorized';
  static const String authTokenExpired = 'auth_token_expired';
  static const String authUserNotFound = 'auth_user_not_found';

  // Resource Related
  static const String resourceNotFound = 'resource_not_found';
  static const String resourceAlreadyExists = 'resource_already_exists';

  // Validation
  static const String invalidRequest = 'invalid_request';
  static const String validationFailed = 'validation_failed';

  // Server
  static const String serverInternalError = 'internal_server_error';
  static const String serviceUnavailable = 'service_unavailable';

  // Network (Client-side specific)
  static const String networkTimeout = 'network_timeout';
  static const String networkOffline = 'network_offline';
}
