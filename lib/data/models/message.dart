import 'package:hive/hive.dart';

part 'message.g.dart';

/// 空字串轉 null 輔助函數
String? _nullIfEmpty(String? value) => (value == null || value.isEmpty) ? null : value;

/// 留言
@HiveType(typeId: 2)
class Message extends HiveObject {
  /// 後端識別用 UUID
  @HiveField(0)
  String uuid;

  /// 父留言 UUID (若為 null 則為主留言，否則為子留言)
  @HiveField(1)
  String? parentId;

  /// 發文者暱稱
  @HiveField(2)
  String user;

  /// 留言分類：Gear, Plan, Misc
  @HiveField(3)
  String category;

  /// 留言內容
  @HiveField(4)
  String content;

  /// 發文時間
  @HiveField(5)
  DateTime timestamp;

  /// 使用者頭像
  @HiveField(6, defaultValue: '🐻')
  String avatar;

  Message({
    this.uuid = '',
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
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      uuid: json['uuid']?.toString() ?? json['message_id']?.toString() ?? '',
      parentId: _nullIfEmpty(json['parent_id']?.toString()),
      user: json['user']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '🐻',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'parent_id': parentId,
      'user': user,
      'category': category,
      'content': content,
      'avatar': avatar,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
