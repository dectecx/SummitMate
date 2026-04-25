import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_api_models.freezed.dart';
part 'trip_api_models.g.dart';

// ── Responses ──

/// 行程回應（對應 TripGetResponse / TripCreateResponse / TripUpdateResponse）
@freezed
abstract class TripResponse with _$TripResponse {
  const factory TripResponse({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    String? description,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'day_names', defaultValue: <String>[]) required List<String> dayNames,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _TripResponse;

  factory TripResponse.fromJson(Map<String, dynamic> json) =>
      _$TripResponseFromJson(json);
}

/// 行程列表項目回應（對應 TripListItemResponse）
@freezed
abstract class TripListItemResponse with _$TripListItemResponse {
  const factory TripListItemResponse({
    required String id,
    required String name,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TripListItemResponse;

  factory TripListItemResponse.fromJson(Map<String, dynamic> json) =>
      _$TripListItemResponseFromJson(json);
}

/// 行程成員回應（對應 TripMemberListItemResponse）
@freezed
abstract class TripMemberResponse with _$TripMemberResponse {
  const factory TripMemberResponse({
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
    @JsonKey(name: 'user_metadata') required TripMemberUserMetadata userMetadata,
  }) = _TripMemberResponse;

  factory TripMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$TripMemberResponseFromJson(json);
}

/// 成員的使用者 metadata（對應 User schema）
@freezed
abstract class TripMemberUserMetadata with _$TripMemberUserMetadata {
  const factory TripMemberUserMetadata({
    required String id,
    required String nickname,
    required String email,
    String? avatar,
    required String role,
  }) = _TripMemberUserMetadata;

  factory TripMemberUserMetadata.fromJson(Map<String, dynamic> json) =>
      _$TripMemberUserMetadataFromJson(json);
}

// ── Requests ──

/// 建立行程請求（對應 TripCreateRequest）
@freezed
abstract class TripCreateRequest with _$TripCreateRequest {
  const factory TripCreateRequest({
    required String name,
    @JsonKey(name: 'start_date') required DateTime startDate,
    String? description,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'day_names') List<String>? dayNames,
  }) = _TripCreateRequest;

  factory TripCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$TripCreateRequestFromJson(json);
}

/// 更新行程請求（對應 TripUpdateRequest）
@freezed
abstract class TripUpdateRequest with _$TripUpdateRequest {
  const factory TripUpdateRequest({
    String? name,
    String? description,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'day_names') List<String>? dayNames,
    @JsonKey(name: 'last_updated_at') DateTime? lastUpdatedAt,
  }) = _TripUpdateRequest;

  factory TripUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$TripUpdateRequestFromJson(json);
}

/// 新增成員請求（對應 AddMemberRequest）
@freezed
abstract class AddMemberRequest with _$AddMemberRequest {
  const factory AddMemberRequest({
    required String email,
  }) = _AddMemberRequest;

  factory AddMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddMemberRequestFromJson(json);
}

/// 更新成員角色請求
@freezed
abstract class UpdateMemberRoleRequest with _$UpdateMemberRoleRequest {
  const factory UpdateMemberRoleRequest({
    required String role,
  }) = _UpdateMemberRoleRequest;

  factory UpdateMemberRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMemberRoleRequestFromJson(json);
}
