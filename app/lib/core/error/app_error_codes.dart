/// 應用程式常見錯誤代碼常數
/// 用於前端業務邏輯判斷，應對齊後端定義的錯誤代碼。
class AppErrorCodes {
  // --- Auth Related ---
  static const String unauthorized = 'unauthorized';
  static const String invalidCredentials = 'invalid_credentials';
  static const String emailAlreadyExists = 'email_already_exists';
  static const String permissionDenied = 'permission_denied';
  static const String userNotFound = 'user_not_found';
  static const String tokenExpired = 'token_expired';
  static const String invalidVerificationCode = 'invalid_verification_code';
  static const String verificationCodeExpired = 'verification_code_expired';

  // --- Trip Related ---
  static const String tripNotFound = 'trip_not_found';
  static const String cannotRemoveOwner = 'cannot_remove_owner';
  static const String updateConflict = 'update_conflict';

  // --- Resource Related ---
  static const String resourceNotFound = 'resource_not_found';
  static const String invalidBody = 'invalid_body';

  // --- Group Event Related ---
  static const String eventNotFound = 'event_not_found';
  static const String eventPermissionDenied = 'event_permission_denied';

  // --- Validation ---
  static const String passwordTooShort = 'password_too_short';
  static const String passwordTooWeak = 'password_too_weak';
  static const String invalidEmail = 'invalid_email';

  // --- Client Side Specific ---
  static const String networkTimeout = 'network_timeout';
  static const String networkOffline = 'network_offline';
  static const String unknownError = 'unknown_error';
}
