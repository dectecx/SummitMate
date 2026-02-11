import 'package:hive/hive.dart';
import '../../../core/error/result.dart';
import '../../models/message.dart';

/// Message Repository 抽象介面
/// 定義留言資料存取的契約 (支援 Offline-First)
abstract interface class IMessageRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有留言
  Future<Result<List<Message>, Exception>> getAllMessages();

  /// 依分類取得留言
  Future<Result<List<Message>, Exception>> getMessagesByCategory(String category);

  /// 取得主留言 (非回覆)
  Future<Result<List<Message>, Exception>> getMainMessages({String? category});

  /// 取得子留言 (回覆)
  Future<Result<List<Message>, Exception>> getReplies(String parentId);

  /// 依 ID 取得留言
  Future<Result<Message?, Exception>> getById(String id);

  /// 新增留言
  Future<Result<void, Exception>> addMessage(Message message);

  /// 刪除留言 (依 ID)
  Future<Result<void, Exception>> deleteById(String id);

  /// 清除所有留言
  Future<Result<void, Exception>> clearAll();

  // ========== Sync Operations ==========

  /// 批次同步留言 (從雲端)
  Future<Result<void, Exception>> syncFromCloud(List<Message> cloudMessages);

  /// 取得待上傳的本地留言
  Future<Result<List<Message>, Exception>> getPendingMessages(Set<String> cloudIds);

  /// 儲存最後同步時間
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  Future<Result<DateTime?, Exception>> getLastSyncTime();

  /// 觸發同步 (Fetch & Update)
  Future<Result<void, Exception>> sync(String tripId);

  // ========== Watch ==========

  /// 監聽留言變更
  Stream<BoxEvent> watchAllMessages();
}
