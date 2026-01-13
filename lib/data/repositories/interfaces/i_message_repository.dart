import 'package:hive/hive.dart';
import '../../../core/error/result.dart';
import '../../models/message.dart';

/// Message Repository 抽象介面
/// 定義留言資料存取的契約
abstract interface class IMessageRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  /// 取得所有留言
  Future<Result<List<Message>, Exception>> getAllMessages();

  /// 依分類取得留言
  ///
  /// [category] 留言分類 (e.g., "Gear")
  Future<Result<List<Message>, Exception>> getMessagesByCategory(String category);

  /// 取得主留言 (非回覆)
  ///
  /// [category] 選擇性篩選分類
  Future<Result<List<Message>, Exception>> getMainMessages({String? category});

  /// 取得子留言 (回覆)
  ///
  /// [parentId] 父留言的 ID
  Future<Result<List<Message>, Exception>> getReplies(String parentId);

  /// 依 ID 取得留言
  ///
  /// [id] 留言 ID
  Future<Result<Message?, Exception>> getById(String id);

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  Future<Result<void, Exception>> addMessage(Message message);

  /// 刪除留言 (依 ID)
  ///
  /// [id] 欲刪除的留言 ID
  Future<Result<void, Exception>> deleteById(String id);

  /// 批次同步留言 (從雲端)
  ///
  /// [cloudMessages] 雲端下載的留言列表
  Future<Result<void, Exception>> syncFromCloud(List<Message> cloudMessages);

  /// 取得待上傳的本地留言
  ///
  /// [cloudIds] 已存在於雲端的 ID 集合 (用於比對)
  Future<Result<List<Message>, Exception>> getPendingMessages(Set<String> cloudIds);

  /// 監聽留言變更
  Stream<BoxEvent> watchAllMessages();

  /// 儲存最後同步時間
  ///
  /// [time] 同步時間
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  Future<Result<DateTime?, Exception>> getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  ///
  /// [tripId] 當前行程 ID
  Future<Result<void, Exception>> sync(String tripId);

  /// 清除所有留言
  Future<Result<void, Exception>> clearAll();
}
