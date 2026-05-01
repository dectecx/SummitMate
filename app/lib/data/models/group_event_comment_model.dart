import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/group_event_comment.dart';

part 'group_event_comment_model.g.dart';

/// 揪團留言持久化模型 (Persistence Model)
@HiveType(typeId: 16)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupEventCommentModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String eventId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String userName;

  @HiveField(5)
  final String userAvatar;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  const GroupEventCommentModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 轉換為 Domain Entity
  GroupEventComment toDomain() {
    return GroupEventComment(
      id: id,
      eventId: eventId,
      userId: userId,
      content: content,
      userName: userName,
      userAvatar: userAvatar,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// 從 Domain Entity 建立 Model
  factory GroupEventCommentModel.fromDomain(GroupEventComment entity) {
    return GroupEventCommentModel(
      id: entity.id,
      eventId: entity.eventId,
      userId: entity.userId,
      content: entity.content,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory GroupEventCommentModel.fromJson(Map<String, dynamic> json) => _$GroupEventCommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupEventCommentModelToJson(this);
}
