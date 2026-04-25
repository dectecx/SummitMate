import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_api_models.freezed.dart';
part 'user_api_models.g.dart';

// ── Response ──

/// 使用者回應（對應 User schema）
@freezed
abstract class UserResponse with _$UserResponse {
  const factory UserResponse({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(defaultValue: '🐻') String? avatar,
    @JsonKey(name: 'role_id', defaultValue: '') required String roleId,
    @JsonKey(defaultValue: 'member') required String role,
    @JsonKey(defaultValue: []) required List<String> permissions,
    @JsonKey(name: 'is_verified', defaultValue: false) required bool isVerified,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserResponse;

  factory UserResponse.fromJson(Map<String, dynamic> json) => _$UserResponseFromJson(json);
}

// ── Request ──

/// 更新使用者資料請求
@freezed
abstract class UserUpdateRequest with _$UserUpdateRequest {
  const factory UserUpdateRequest({@JsonKey(name: 'display_name') String? displayName, String? avatar}) =
      _UserUpdateRequest;

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) => _$UserUpdateRequestFromJson(json);
}
