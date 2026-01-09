import '../../models/message.dart';

abstract class IMessageRemoteDataSource {
  /// 取得雲端留言列表 (透過 sync/getAll API)
  Future<List<Message>> fetchMessages(String tripId);
}
