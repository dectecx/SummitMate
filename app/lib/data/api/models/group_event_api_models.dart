import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event_api_models.freezed.dart';
part 'group_event_api_models.g.dart';

// ── Requests ──

/// 建立揪團請求
@freezed
class GroupEventCreateRequest with _$GroupEventCreateRequest {
  const factory GroupEventCreateRequest({
    required String title,
    required String description,
    required String location,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'max_members') required int maxMembers,
    @JsonKey(name: 'approval_required') required bool approvalRequired,
    @JsonKey(name: 'private_message') String? privateMessage,
    @JsonKey(name: 'linked_trip_id') String? linkedTripId,
  }) = _GroupEventCreateRequest;

  factory GroupEventCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventCreateRequestFromJson(json);
}

/// 更新揪團請求
@freezed
class GroupEventUpdateRequest with _$GroupEventUpdateRequest {
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

  factory GroupEventUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventUpdateRequestFromJson(json);
}

/// 更新揪團狀態請求
@freezed
class GroupEventStatusRequest with _$GroupEventStatusRequest {
  const factory GroupEventStatusRequest({
    required String status,
    String? action,
  }) = _GroupEventStatusRequest;

  factory GroupEventStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventStatusRequestFromJson(json);
}

/// 申請揪團請求
@freezed
class GroupEventApplyRequest with _$GroupEventApplyRequest {
  const factory GroupEventApplyRequest({
    String? message,
  }) = _GroupEventApplyRequest;

  factory GroupEventApplyRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventApplyRequestFromJson(json);
}

/// 審核申請請求
@freezed
class GroupEventReviewRequest with _$GroupEventReviewRequest {
  const factory GroupEventReviewRequest({
    required String action,
  }) = _GroupEventReviewRequest;

  factory GroupEventReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventReviewRequestFromJson(json);
}

/// 新增留言請求
@freezed
class GroupEventCommentRequest with _$GroupEventCommentRequest {
  const factory GroupEventCommentRequest({
    required String content,
  }) = _GroupEventCommentRequest;

  factory GroupEventCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupEventCommentRequestFromJson(json);
}
