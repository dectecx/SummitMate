import 'package:hive/hive.dart';
import '../../models/message.dart';

/// Message Repository 抽象介面
/// 定義留言資料存取的契約
abstract interface class IMessageRepository {
  /// 初始化
  Future<void> init();

  /// 取得所有留言
  List<Message> getAllMessages();

  /// 依分類取得留言
  List<Message> getMessagesByCategory(String category);

  /// 取得主留言 (非回覆)
  List<Message> getMainMessages({String? category});

  /// 取得子留言 (回覆)
  List<Message> getReplies(String parentUuid);

  /// 依 UUID 取得留言
  Message? getByUuid(String uuid);

  /// 新增留言
  Future<void> addMessage(Message message);

  /// 刪除留言 (依 UUID)
  Future<void> deleteByUuid(String uuid);

  /// 批次同步留言 (從雲端)
  Future<void> syncFromCloud(List<Message> cloudMessages);

  /// 取得待上傳的本地留言
  List<Message> getPendingMessages(Set<String> cloudUuids);

  /// 監聽留言變更
  Stream<BoxEvent> watchAllMessages();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  Future<void> sync(String tripId);

  /// 清除所有留言
  Future<void> clearAll();
}
