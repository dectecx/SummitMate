import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll.freezed.dart';
part 'poll.g.dart';

/// 投票領域實體 (Domain Entity)
@freezed
abstract class Poll with _$Poll {
  const Poll._();

  const factory Poll({
    required String id,
    @Default('') String tripId,
    required String title,
    @Default('') String description,
    required String creatorId,
    DateTime? deadline,
    @Default(false) bool isAllowAddOption,
    @Default(20) int maxOptionLimit,
    @Default(false) bool allowMultipleVotes,
    @Default('realtime') String resultDisplayType,
    @Default('active') String status,
    @Default([]) List<PollOption> options,
    @Default([]) List<String> myVotes,
    @Default(0) int totalVotes,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _Poll;

  /// 是否已過期
  bool get isExpired {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// 是否活動中 (未結束且未過期)
  bool get isActive => status == 'active' && !isExpired;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}

/// 投票選項領域實體 (Domain Entity)
@freezed
abstract class PollOption with _$PollOption {
  const PollOption._();

  const factory PollOption({
    required String id,
    required String pollId,
    required String text,
    required String creatorId,
    @Default(0) int voteCount,
    @Default([]) List<Map<String, dynamic>> voters,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);
}
