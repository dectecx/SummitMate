import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
// TODO: Phase 2 完成後將 Message 改為 domain/entities/message.dart
import '../../data/models/message.dart';

/// 留言資料倉庫介面（支援 Offline-First）
///
/// 定義留言資料存取的契約。
abstract interface class IMessageRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  /// 從本地取得行程留言
  ///
  /// [tripId] 行程 ID
  List<Message> getByTripId(String tripId);

  /// 從雲端取得分頁留言
  ///
  /// [tripId] 行程 ID
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(String tripId, {int? page, int? limit});

  /// 儲存留言到本地
  ///
  /// [message] 要儲存的留言
  Future<Result<void, Exception>> saveLocally(Message message);

  /// 新增留言（雲端）
  ///
  /// [tripId] 行程 ID
  /// [content] 留言內容
  /// [replyToId] 回覆的留言 ID（可選）
  Future<Result<String, Exception>> addMessage({required String tripId, required String content, String? replyToId});

  /// 刪除留言（雲端 + 本地）
  ///
  /// [tripId] 行程 ID
  /// [messageId] 留言 ID
  Future<Result<void, Exception>> deleteById(String tripId, String messageId);

  /// 清除行程所有留言（本地）
  ///
  /// [tripId] 行程 ID
  Future<Result<void, Exception>> clearByTripId(String tripId);
}
