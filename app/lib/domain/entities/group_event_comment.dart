import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event_comment.freezed.dart';
part 'group_event_comment.g.dart';

/// 揪團留言領域實體 (Domain Entity)
@freezed
abstract class GroupEventComment with _$GroupEventComment {
  const factory GroupEventComment({
    required String id,
    required String eventId,
    required String userId,
    required String content,
    required String userName,
    required String userAvatar,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GroupEventComment;

  factory GroupEventComment.fromJson(Map<String, dynamic> json) => _$GroupEventCommentFromJson(json);
}
