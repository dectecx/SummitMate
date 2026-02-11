import 'package:hive/hive.dart';
import '../../models/itinerary_item.dart';

/// 行程項目 (ItineraryItem) 的本地資料來源介面
///
/// 負責定義對本地資料庫 (如 Hive) 的 CRUD 操作規範。
abstract class IItineraryLocalDataSource {
  /// 初始化資料來源 (例如開啟 Box)
  Future<void> init();

  /// 取得所有行程項目
  List<ItineraryItem> getAll();

  /// 透過 Key 取得單一行程項目
  ///
  /// [key] 通常為 Hive 的 auto-increment key 或 uuid
  ItineraryItem? getByKey(dynamic key);

  /// 新增行程項目
  ///
  /// [item] 欲新增的項目
  Future<void> add(ItineraryItem item);

  /// 更新行程項目
  ///
  /// [key] 目標項目的鍵值
  /// [item] 更新後的項目資料
  Future<void> update(dynamic key, ItineraryItem item);

  /// 刪除行程項目
  ///
  /// [key] 目標項目的鍵值
  Future<void> delete(dynamic key);

  /// 清除所有行程項目
  Future<void> clear();

  /// 監聽資料變更流
  Stream<BoxEvent> watch();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  DateTime? getLastSyncTime();
}
