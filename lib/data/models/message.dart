import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

/// 空字串轉 null 輔助函數
String? _nullIfEmpty(String? value) => (value == null || value.isEmpty) ? null : value;

/// 留言
@HiveType(typeId: 2)
@JsonSerializable(fieldRename: FieldRename.snake)
class Message extends HiveObject {
  /// 後端識別用 ID (PK)
  @HiveField(0)
  String id;

  /// 關聯的行程 ID (FK → Trip，null = 全域留言)
  @HiveField(1)
  @JsonKey(fromJson: _nullIfEmpty)
  String? tripId;

  /// 父留言 UUID (FK → Message，若為 null 則為主留言)
  @HiveField(2)
  @JsonKey(fromJson: _nullIfEmpty)
  String? parentId;

  /// 發文者暱稱
  @HiveField(3)
  @JsonKey(defaultValue: '')
  String user;

  /// 留言分類：Gear, Plan, Misc
  @HiveField(4)
  @JsonKey(defaultValue: '')
  String category;

  /// 留言內容
  @HiveField(5)
  @JsonKey(defaultValue: '')
  String content;

  /// 發文時間
  @HiveField(6)
  DateTime timestamp;

  /// 使用者頭像
  @HiveField(7, defaultValue: '🐻')
  @JsonKey(defaultValue: '🐻')
  String avatar;

  Message({
    required this.id,
    this.tripId,
    this.parentId,
    this.user = '',
    this.category = '',
    this.content = '',
    this.avatar = '🐻',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 是否為回覆留言
  bool get isReply => parentId != null;

  /// 從 JSON 建立
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
