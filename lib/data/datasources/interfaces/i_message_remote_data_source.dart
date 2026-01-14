import '../../models/message.dart';

/// 留言訊息 (Message) 的遠端資料來源介面
///
/// 負責定義與後端 API (GAS) 進行訊息資料交換的操作。
abstract class IMessageRemoteDataSource {
  /// 取得雲端留言列表 (透過 sync/getAll API)
  ///
  /// [tripId] 指定的行程 ID
  Future<List<Message>> getMessages(String tripId);

  /// 新增留言
  ///
  /// [message] 欲新增的留言物件
  Future<void> addMessage(Message message);

  /// 刪除留言
  ///
  /// [id] 留言 ID
  Future<void> deleteMessage(String id);
}
