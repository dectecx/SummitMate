import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final String userId;
  final String? userName;
  final bool isGuest;
  final bool isOffline;

  const AuthAuthenticated({required this.userId, this.userName, this.isGuest = false, this.isOffline = false});

  @override
  List<Object?> get props => [userId, userName, isGuest, isOffline];
}

final class AuthUnauthenticated extends AuthState {}

final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

final class AuthOperationSuccess extends AuthState {
  final String message;
  const AuthOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

final class AuthRequiresVerification extends AuthState {
  final String email;
  const AuthRequiresVerification(this.email);

  @override
  List<Object?> get props => [email];
}
