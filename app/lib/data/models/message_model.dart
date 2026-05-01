import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

/// 空字串轉 null 輔助函數
String? _nullIfEmpty(String? value) => (value == null || value.isEmpty) ? null : value;

/// 留言持久化模型 (Persistence Model)
@HiveType(typeId: 2)
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(fromJson: _nullIfEmpty)
  final String? tripId;

  @HiveField(2)
  @JsonKey(fromJson: _nullIfEmpty)
  final String? parentId;

  @HiveField(3)
  @JsonKey(defaultValue: '')
  final String userId;

  @HiveField(4)
  @JsonKey(defaultValue: '')
  final String user;

  @HiveField(5, defaultValue: '🐻')
  @JsonKey(defaultValue: '🐻')
  final String avatar;

  @HiveField(6)
  @JsonKey(defaultValue: '')
  final String category;

  @HiveField(7)
  @JsonKey(defaultValue: '')
  final String content;

  @HiveField(8)
  final DateTime timestamp;

  @HiveField(9)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(10)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(11)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @HiveField(12)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  MessageModel({
    required this.id,
    this.tripId,
    this.parentId,
    this.userId = '',
    this.user = '',
    this.avatar = '🐻',
    this.category = '',
    this.content = '',
    required this.timestamp,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// 轉換為 Domain Entity
  Message toDomain() {
    return Message(
      id: id,
      tripId: tripId,
      parentId: parentId,
      userId: userId,
      user: user,
      avatar: avatar,
      category: category,
      content: content,
      timestamp: timestamp,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory MessageModel.fromDomain(Message entity) {
    return MessageModel(
      id: entity.id,
      tripId: entity.tripId,
      parentId: entity.parentId,
      userId: entity.userId,
      user: entity.user,
      avatar: entity.avatar,
      category: entity.category,
      content: entity.content,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}
