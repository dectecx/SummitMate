import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/message.dart';

/// Message Repository 抽象介面
/// 定義留言資料存取的契約 (支援 Offline-First)
abstract interface class IMessageRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  /// 從本地取得行程留言
  List<Message> getByTripId(String tripId);

  /// 從雲端取得分頁留言
  Future<Result<PaginatedList<Message>, Exception>> getRemoteMessages(String tripId, {int? page, int? limit});

  /// 儲存留言到本地
  Future<Result<void, Exception>> saveLocally(Message message);

  /// 新增留言
  Future<Result<String, Exception>> addMessage({required String tripId, required String content, String? replyToId});

  /// 刪除留言
  Future<Result<void, Exception>> deleteById(String tripId, String messageId);

  /// 清除行程所有留言
  Future<Result<void, Exception>> clearByTripId(String tripId);
}
