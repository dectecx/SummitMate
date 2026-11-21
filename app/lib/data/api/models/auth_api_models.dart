import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_api_models.dart';

part 'auth_api_models.freezed.dart';
part 'auth_api_models.g.dart';

// ── Response ──

/// 登入／刷新 Token 回應（對應 AuthResponse schema）
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    required UserResponse user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}

/// 註冊回應（對應 RegisterResponse schema）。註冊不會簽發 Token。
@freezed
abstract class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({required UserResponse user}) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => _$RegisterResponseFromJson(json);
}

// ── Request ──

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({required String email, required String password}) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(includeIfNull: false) String? avatar,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}

@freezed
abstract class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({@JsonKey(name: 'refresh_token') required String refreshToken}) =
      _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);
}

/// 登出請求。提供 refreshToken 時，後端會一併註銷，避免登出後仍能換發新 Token。
@freezed
abstract class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({@JsonKey(name: 'refresh_token', includeIfNull: false) String? refreshToken}) =
      _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) => _$LogoutRequestFromJson(json);
}

@freezed
abstract class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    @JsonKey(name: 'old_password') required String oldPassword,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestFromJson(json);
}

@freezed
abstract class VerifyEmailRequest with _$VerifyEmailRequest {
  const factory VerifyEmailRequest({required String email, required String code}) = _VerifyEmailRequest;

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) => _$VerifyEmailRequestFromJson(json);
}

@freezed
abstract class ResendVerificationRequest with _$ResendVerificationRequest {
  const factory ResendVerificationRequest({required String email}) = _ResendVerificationRequest;

  factory ResendVerificationRequest.fromJson(Map<String, dynamic> json) => _$ResendVerificationRequestFromJson(json);
}
