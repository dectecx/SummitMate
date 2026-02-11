import 'package:hive/hive.dart';
import '../../models/message.dart';

/// 留言訊息 (Message) 的本地資料來源介面
///
/// 負責定義對本地訊息資料庫 (如 Hive) 的 CRUD 操作。
abstract class IMessageLocalDataSource {
  /// 初始化資料來源 (開啟 Box)
  Future<void> init();

  /// 取得所有訊息
  List<Message> getAll();

  /// 透過 ID 取得單一訊息
  ///
  /// [id] 訊息 ID
  Message? getById(String id);

  /// 新增訊息
  ///
  /// [message] 欲新增的訊息物件
  Future<void> add(Message message);

  /// 刪除訊息 (依 Key)
  ///
  /// [key] 訊息的本地鍵值 (Hive Key)
  Future<void> delete(dynamic key);

  /// 清除所有訊息
  Future<void> clear();

  /// 監聽資料變更流
  Stream<BoxEvent> watch();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();
}
