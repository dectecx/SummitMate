import '../core/auth/auth_api.dart';

/// Turns an error from the auth layer into a message for the person using the app.
String authErrorMessage(Object error) {
  if (error is AuthNetworkException) return '無法連線，請檢查網路後再試';
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => '帳號或密碼錯誤',
      'email_already_exists' => '這個 Email 已經註冊過了，請直接登入',
      'invalid_verification_code' => '驗證碼不正確',
      'verification_code_expired' => '驗證碼已過期，請重新發送',
      'too_many_requests' => '嘗試次數太多，請稍後再試',
      'invalid_email' => 'Email 格式不正確',
      'password_too_short' => '密碼至少需要 8 個字元',
      'password_too_weak' => '密碼需要同時包含字母與數字',
      'wrong_current_password' => '目前的密碼不正確',
      'account_disabled' => '這個帳號已停用',
      _ => '發生錯誤，請稍後再試',
    };
  }
  return '發生錯誤，請稍後再試';
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return '請輸入 Email';
  return _email.hasMatch(s) ? null : 'Email 格式不正確';
}

String? validateNewPassword(String? v) {
  final s = v ?? '';
  if (s.length < 8) return '密碼至少需要 8 個字元';
  if (s.length > 72) return '密碼不可超過 72 個字元';
  if (!s.contains(RegExp(r'[A-Za-z]')) || !s.contains(RegExp(r'[0-9]'))) return '密碼需要同時包含字母與數字';
  return null;
}
