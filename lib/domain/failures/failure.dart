import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// General server failure (500, etc.)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Network failure (No internet, timeout)
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '網路連線異常，請檢查您的網路設定']) : super(code: 'NETWORK_ERROR');
}

/// Cache failure (Hive read/write error)
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Authentication failure (Invalid credentials, expired token)
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Validation failure (Invalid input)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Not Found failure (Resource not found)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Unknown/Unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}
