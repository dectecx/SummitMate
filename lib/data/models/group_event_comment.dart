import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_event_comment.g.dart';

/// 揪團留言
@HiveType(typeId: 16)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupEventComment {
  /// 留言 ID (PK)
  @HiveField(0)
  final String id;

  /// 揪團 ID (FK)
  @HiveField(1)
  final String eventId;

  /// 使用者 ID (FK)
  @HiveField(2)
  final String userId;

  /// 留言內容
  @HiveField(3)
  final String content;

  /// 使用者名稱 (快照)
  @HiveField(4)
  final String userName;

  /// 使用者頭像 (快照)
  @HiveField(5)
  final String userAvatar;

  /// 建立時間
  @HiveField(6)
  final DateTime createdAt;

  /// 更新時間
  @HiveField(7)
  final DateTime updatedAt;

  const GroupEventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupEventComment.fromJson(Map<String, dynamic> json) => _$GroupEventCommentFromJson(json);

  Map<String, dynamic> toJson() => _$GroupEventCommentToJson(this);

  GroupEventComment copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? content,
    String? userName,
    String? userAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupEventComment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
