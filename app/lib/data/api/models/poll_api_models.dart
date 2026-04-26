import 'package:freezed_annotation/freezed_annotation.dart';
import 'pagination_api_models.dart';

part 'poll_api_models.freezed.dart';
part 'poll_api_models.g.dart';

@freezed
abstract class PollPaginationResponse with _$PollPaginationResponse {
  const factory PollPaginationResponse({required List<PollResponse> items, required PaginationMetadata pagination}) =
      _PollPaginationResponse;

  factory PollPaginationResponse.fromJson(Map<String, dynamic> json) => _$PollPaginationResponseFromJson(json);
}

// ── Response ──

/// 投票選項回應
@freezed
abstract class PollOptionResponse with _$PollOptionResponse {
  const factory PollOptionResponse({
    required String id,
    @JsonKey(name: 'poll_id') required String pollId,
    required String text,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'vote_count', defaultValue: 0) required int voteCount,
    @JsonKey(defaultValue: []) required List<Map<String, dynamic>> voters,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _PollOptionResponse;

  factory PollOptionResponse.fromJson(Map<String, dynamic> json) => _$PollOptionResponseFromJson(json);
}

/// 投票回應（對應 Poll schema）
@freezed
abstract class PollResponse with _$PollResponse {
  const factory PollResponse({
    required String id,
    required String title,
    @JsonKey(defaultValue: '') required String description,
    @JsonKey(name: 'creator_id') required String creatorId,
    DateTime? deadline,
    @JsonKey(name: 'is_allow_add_option', defaultValue: false) required bool isAllowAddOption,
    @JsonKey(name: 'max_option_limit', defaultValue: 20) required int maxOptionLimit,
    @JsonKey(name: 'allow_multiple_votes', defaultValue: false) required bool allowMultipleVotes,
    @JsonKey(name: 'result_display_type', defaultValue: 'realtime') required String resultDisplayType,
    @JsonKey(defaultValue: 'active') required String status,
    @JsonKey(defaultValue: []) required List<PollOptionResponse> options,
    @JsonKey(name: 'my_votes', defaultValue: []) required List<String> myVotes,
    @JsonKey(name: 'total_votes', defaultValue: 0) required int totalVotes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _PollResponse;

  factory PollResponse.fromJson(Map<String, dynamic> json) => _$PollResponseFromJson(json);
}

// ── Requests ──

/// 建立投票請求
@freezed
abstract class PollCreateRequest with _$PollCreateRequest {
  const factory PollCreateRequest({
    required String title,
    @JsonKey(defaultValue: '') String? description,
    DateTime? deadline,
    @JsonKey(name: 'initial_options', defaultValue: []) required List<String> initialOptions,
    @JsonKey(name: 'is_allow_add_option', defaultValue: false) required bool isAllowAddOption,
    @JsonKey(name: 'max_option_limit', defaultValue: 20) required int maxOptionLimit,
    @JsonKey(name: 'allow_multiple_votes', defaultValue: false) required bool allowMultipleVotes,
    @JsonKey(name: 'result_display_type', defaultValue: 'realtime') required String resultDisplayType,
  }) = _PollCreateRequest;

  factory PollCreateRequest.fromJson(Map<String, dynamic> json) => _$PollCreateRequestFromJson(json);
}

/// 新增投票選項請求
@freezed
abstract class PollOptionRequest with _$PollOptionRequest {
  const factory PollOptionRequest({required String text}) = _PollOptionRequest;

  factory PollOptionRequest.fromJson(Map<String, dynamic> json) => _$PollOptionRequestFromJson(json);
}
