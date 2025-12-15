import 'package:isar/isar.dart';

part 'message.g.dart';

/// 留言 Collection
/// 來源：與 Google Sheets 雙向同步
@collection
class Message {
  /// Isar Auto ID
  Id? id;

  /// 後端識別用 UUID
  @Index(unique: true)
  String uuid = '';

  /// 父留言 UUID (若為 null 則為主留言，否則為子留言)
  @Index()
  String? parentId;

  /// 發文者暱稱
  String user = '';

  /// 留言分類：Gear, Plan, Misc
  @Index()
  String category = '';

  /// 留言內容
  String content = '';

  /// 發文時間
  @Index()
  DateTime timestamp = DateTime.now();

  /// 建構子
  Message();

  /// 是否為回覆留言
  @ignore
  bool get isReply => parentId != null;

  /// 從 JSON 建立 (用於 Google Sheets 資料解析)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message()
      ..uuid = json['uuid'] as String? ?? json['message_id'] as String? ?? ''
      ..parentId = json['parent_id'] as String?
      ..user = json['user'] as String? ?? ''
      ..category = json['category'] as String? ?? ''
      ..content = json['content'] as String? ?? ''
      ..timestamp = json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now();
  }

  /// 轉換為 JSON (用於 API 請求)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'parent_id': parentId,
      'user': user,
      'category': category,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
