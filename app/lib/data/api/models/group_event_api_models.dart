import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event_api_models.freezed.dart';
part 'group_event_api_models.g.dart';

// ── Response ──

/// 揪團回應（對應 GroupEvent schema）
@freezed
abstract class GroupEventResponse with _$GroupEventResponse {
  const factory GroupEventResponse({
    required String id,
    @JsonKey(name: 'creator_id') required String creatorId,
    required String title,
    @JsonKey(defaultValue: '') required String description,
    @JsonKey(defaultValue: '') required String location,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(defaultValue: 'open') required String status,
    @JsonKey(name: 'max_members', defaultValue: 10) required int maxMembers,
    @JsonKey(name: 'application_count', defaultValue: 0) required int applicationCount,
    @JsonKey(name: 'total_application_count', defaultValue: 0) required int totalApplicationCount,
    @JsonKey(name: 'approval_required', defaultValue: false) required bool approvalRequired,
    @JsonKey(name: 'private_message', defaultValue: '') required String privateMessage,
    @JsonKey(name: 'linked_trip_id') String? linkedTripId,
    @JsonKey(name: 'like_count', defaultValue: 0) required int likeCount,
    @JsonKey(name: 'comment_count', defaultValue: 0) required int commentCount,
    @JsonKey(name: 'is_liked', defaultValue: false) required bool isLiked,
    @JsonKey(name: 'my_application_status') String? myApplicationStatus,
    @JsonKey(name: 'creator_name', defaultValue: '') required String creatorName,
    @JsonKey(name: 'creator_avatar', defaultValue: '🐻') required String creatorAvatar,
    @JsonKey(name: 'latest_comments', defaultValue: []) required List<GroupEventCommentResponse> latestComments,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _GroupEventResponse;

  factory GroupEventResponse.fromJson(Map<String, dynamic> json) => _$GroupEventResponseFromJson(json);
}

/// 揪團報名紀錄回應
@freezed
abstract class GroupEventApplicationResponse with _$GroupEventApplicationResponse {
  const factory GroupEventApplicationResponse({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(defaultValue: 'pending') required String status,
    @JsonKey(defaultValue: '') required String message,
    @JsonKey(name: 'user_name', defaultValue: '') required String userName,
    @JsonKey(name: 'user_avatar', defaultValue: '🐻') required String userAvatar,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _GroupEventApplicationResponse;

  factory GroupEventApplicationResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupEventApplicationResponseFromJson(json);
}

/// 揪團留言回應
@freezed
abstract class GroupEventCommentResponse with _$GroupEventCommentResponse {
  const factory GroupEventCommentResponse({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'user_id') required String userId,
    required String content,
    @JsonKey(name: 'user_name', defaultValue: '') required String userName,
    @JsonKey(name: 'user_avatar', defaultValue: '🐻') required String userAvatar,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _GroupEventCommentResponse;

  factory GroupEventCommentResponse.fromJson(Map<String, dynamic> json) => _$GroupEventCommentResponseFromJson(json);
}

// ── Requests ──

/// 建立揪團請求
@freezed
abstract class GroupEventCreateRequest with _$GroupEventCreateRequest {
  const factory GroupEventCreateRequest({
    required String title,
    required String description,
    required String location,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'max_members', defaultValue: 10) required int maxMembers,
    @JsonKey(name: 'approval_required', defaultValue: false) required bool approvalRequired,
    @JsonKey(name: 'private_message') String? privateMessage,
    @JsonKey(name: 'linked_trip_id') String? linkedTripId,
  }) = _GroupEventCreateRequest;

  factory GroupEventCreateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventCreateRequestFromJson(json);
}

/// 更新揪團請求
@freezed
abstract class GroupEventUpdateRequest with _$GroupEventUpdateRequest {
  const factory GroupEventUpdateRequest({
    String? title,
    String? description,
    String? location,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'max_members') int? maxMembers,
    @JsonKey(name: 'approval_required') bool? approvalRequired,
    @JsonKey(name: 'private_message') String? privateMessage,
  }) = _GroupEventUpdateRequest;

  factory GroupEventUpdateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventUpdateRequestFromJson(json);
}

/// 更新揪團狀態請求
@freezed
abstract class GroupEventStatusRequest with _$GroupEventStatusRequest {
  const factory GroupEventStatusRequest({required String status, String? action}) = _GroupEventStatusRequest;

  factory GroupEventStatusRequest.fromJson(Map<String, dynamic> json) => _$GroupEventStatusRequestFromJson(json);
}

/// 申請揪團請求
@freezed
abstract class GroupEventApplyRequest with _$GroupEventApplyRequest {
  const factory GroupEventApplyRequest({String? message}) = _GroupEventApplyRequest;

  factory GroupEventApplyRequest.fromJson(Map<String, dynamic> json) => _$GroupEventApplyRequestFromJson(json);
}

/// 審核申請請求
@freezed
abstract class GroupEventReviewRequest with _$GroupEventReviewRequest {
  const factory GroupEventReviewRequest({required String action}) = _GroupEventReviewRequest;

  factory GroupEventReviewRequest.fromJson(Map<String, dynamic> json) => _$GroupEventReviewRequestFromJson(json);
}

/// 新增留言請求
@freezed
abstract class GroupEventCommentRequest with _$GroupEventCommentRequest {
  const factory GroupEventCommentRequest({required String content}) = _GroupEventCommentRequest;

  factory GroupEventCommentRequest.fromJson(Map<String, dynamic> json) => _$GroupEventCommentRequestFromJson(json);
}
