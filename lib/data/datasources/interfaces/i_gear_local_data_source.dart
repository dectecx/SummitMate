import 'package:hive/hive.dart';
import '../../models/gear_item.dart';

/// 裝備項目 (GearItem) 的本地資料來源介面
///
/// 負責定義對本地裝備資料庫的 CRUD 操作。
abstract class IGearLocalDataSource {
  /// 初始化資料來源
  Future<void> init();

  /// 取得所有裝備項目
  List<GearItem> getAll();

  /// 根據行程 ID 取得裝備清單
  List<GearItem> getByTripId(String tripId);

  /// 根據類別取得裝備清單
  List<GearItem> getByCategory(String category);

  /// 取得尚未檢查 (checkbox 未勾選) 的裝備
  List<GearItem> getUnchecked();

  /// 透過 Key 取得單一裝備
  GearItem? getByKey(dynamic key);

  /// 新增裝備項目，回傳新建的 Key
  Future<int> add(GearItem item);

  /// 更新裝備項目
  Future<void> update(GearItem item);

  /// 刪除裝備項目
  Future<void> delete(dynamic key);

  /// 清除指定行程的所有裝備
  Future<void> clearByTripId(String tripId);

  /// 清除所有裝備資料
  Future<void> clearAll();

  /// 監聽資料變更流
  Stream<BoxEvent> watch();
}
