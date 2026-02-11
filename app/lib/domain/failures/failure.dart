import 'package:equatable/equatable.dart';

/// 應用程式中所有 Failure 的基底類別
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// 一般伺服器錯誤 (500 等)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// 網路連線錯誤 (無網路、逾時)
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '網路連線異常，請檢查您的網路設定']) : super(code: 'NETWORK_ERROR');
}

/// 快取錯誤 (Hive 讀寫錯誤)
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// 驗證錯誤 (憑證無效、Token 過期)
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// 驗證錯誤 (輸入無效)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// 找不到資源錯誤 (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// 未知/非預期錯誤
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}
