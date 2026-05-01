import '../../../core/models/paginated_list.dart';
import '../../models/message_model.dart';
import '../../../core/error/result.dart';

/// 行程留言板 (Trip Messages) 的遠端資料來源介面
abstract interface class IMessageRemoteDataSource {
  /// 獲取行程留言列表 (支援分頁)
  ///
  /// [tripId] 行程 ID
  /// [page] 頁碼
  /// [limit] 每頁數量
  Future<Result<PaginatedList<MessageModel>, Exception>> getMessages(String tripId, {int? page, int? limit});

  /// 新增留言
  ///
  /// [tripId] 行程 ID
  /// [content] 留言內容
  /// [replyToId] 回覆的留言 ID (可選)
  Future<Result<String, Exception>> addMessage({required String tripId, required String content, String? replyToId});

  /// 刪除留言
  ///
  /// [tripId] 行程 ID
  /// [id] 留言 ID
  Future<Result<void, Exception>> deleteMessage(String tripId, String id);
}
