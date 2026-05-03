import '../../../domain/entities/message.dart';

/// 留言訊息 (Message) 的本地資料來源介面
abstract interface class IMessageLocalDataSource {
  /// 取得所有訊息
  Future<List<Message>> getAll();

  /// 透過 ID 取得單一訊息
  Future<Message?> getById(String id);

  /// 新增訊息
  Future<void> add(Message message);

  /// 刪除訊息 (依 ID)
  Future<void> deleteById(String id);

  /// 清除所有訊息
  Future<void> clear();

  /// 監聽資料變更流
  Stream<List<Message>> watch();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  Future<DateTime?> getLastSyncTime();
}
