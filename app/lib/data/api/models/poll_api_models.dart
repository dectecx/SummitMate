import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll_api_models.freezed.dart';
part 'poll_api_models.g.dart';

// ── Request ──

/// 建立投票請求
@freezed
class PollCreateRequest with _$PollCreateRequest {
  const factory PollCreateRequest({
    required String title,
    @JsonKey(defaultValue: '') String? description,
    DateTime? deadline,
    @JsonKey(name: 'initial_options', defaultValue: <String>[])
    List<String>? initialOptions,
    @JsonKey(name: 'is_allow_add_option', defaultValue: false)
    bool? isAllowAddOption,
    @JsonKey(name: 'max_option_limit', defaultValue: 20) int? maxOptionLimit,
    @JsonKey(name: 'allow_multiple_votes', defaultValue: false)
    bool? allowMultipleVotes,
    @JsonKey(name: 'result_display_type', defaultValue: 'realtime')
    String? resultDisplayType,
  }) = _PollCreateRequest;

  factory PollCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PollCreateRequestFromJson(json);
}

/// 新增投票選項請求
@freezed
class PollOptionRequest with _$PollOptionRequest {
  const factory PollOptionRequest({
    required String text,
  }) = _PollOptionRequest;

  factory PollOptionRequest.fromJson(Map<String, dynamic> json) =>
      _$PollOptionRequestFromJson(json);
}
