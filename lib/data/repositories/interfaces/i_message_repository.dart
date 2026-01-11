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
  ///
  /// [category] 留言分類 (e.g., "Gear")
  List<Message> getMessagesByCategory(String category);

  /// 取得主留言 (非回覆)
  ///
  /// [category] 選擇性篩選分類
  List<Message> getMainMessages({String? category});

  /// 取得子留言 (回覆)
  ///
  /// [parentUuid] 父留言的 UUID
  List<Message> getReplies(String parentUuid);

  /// 依 UUID 取得留言
  ///
  /// [uuid] 留言 UUID
  Message? getByUuid(String uuid);

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  Future<void> addMessage(Message message);

  /// 刪除留言 (依 UUID)
  ///
  /// [uuid] 欲刪除的留言 UUID
  Future<void> deleteByUuid(String uuid);

  /// 批次同步留言 (從雲端)
  ///
  /// [cloudMessages] 雲端下載的留言列表
  Future<void> syncFromCloud(List<Message> cloudMessages);

  /// 取得待上傳的本地留言
  ///
  /// [cloudUuids] 已存在於雲端的 UUID 集合 (用於比對)
  List<Message> getPendingMessages(Set<String> cloudUuids);

  /// 監聽留言變更
  Stream<BoxEvent> watchAllMessages();

  /// 儲存最後同步時間
  ///
  /// [time] 同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  ///
  /// [tripId] 當前行程 ID
  Future<void> sync(String tripId);

  /// 清除所有留言
  Future<void> clearAll();
}
