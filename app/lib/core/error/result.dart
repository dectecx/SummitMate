/// 應用程式自定義異常基類
/// 讓所有失敗都攜帶可讀訊息與錯誤代碼
/// Base class for all application-specific exceptions.
abstract class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, {this.code = 'UNKNOWN_ERROR'});

  @override
  String toString() => '[$code] $message';
}

/// 通用異常 (當無法歸類時使用)
/// Generic exception implementation for general use.
class GeneralException extends AppException {
  const GeneralException(super.message, {super.code = 'GENERAL_ERROR'});
}

/// 結果類別 (Result Monad)
/// S: 成功回傳的資料型別 (Success Type)
/// E: 失敗回傳的異常型別 (Error/Exception Type)
sealed class Result<S, E extends Exception> {
  const Result();
}

/// 成功狀態
/// Success State
final class Success<S, E extends Exception> extends Result<S, E> {
  /// 成功回傳的數值
  final S value;
  const Success(this.value);
}

/// 失敗狀態
/// Failure State
final class Failure<S, E extends Exception> extends Result<S, E> {
  /// 失敗的異常資訊
  final E exception;
  const Failure(this.exception);
}
