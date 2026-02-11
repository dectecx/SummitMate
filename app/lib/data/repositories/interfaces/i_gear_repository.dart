import 'package:hive/hive.dart';
import '../../models/gear_item.dart';

/// Gear Repository 抽象介面
/// 定義裝備資料存取的契約 (本地儲存)
abstract interface class IGearRepository {
  /// 初始化 Repository
  Future<void> init();

  // ========== Data Operations ==========

  /// 取得所有裝備 (依 orderIndex 排序)
  List<GearItem> getAllItems();

  /// 依分類取得裝備
  List<GearItem> getItemsByCategory(String category);

  /// 取得未打包的裝備
  List<GearItem> getUncheckedItems();

  /// 新增裝備
  Future<int> addItem(GearItem item);

  /// 更新裝備
  Future<void> updateItem(GearItem item);

  /// 刪除裝備
  Future<void> deleteItem(dynamic key);

  /// 批量更新裝備順序
  Future<void> updateItemsOrder(List<GearItem> items);

  /// 清除指定行程的所有裝備
  Future<void> clearByTripId(String tripId);

  /// 清除所有裝備 (Debug 用途)
  Future<void> clearAll();

  // ========== Check Operations ==========

  /// 切換打包狀態
  Future<void> toggleChecked(dynamic key);

  /// 重置所有打包狀態
  Future<void> resetAllChecked();

  // ========== Statistics ==========

  /// 計算總重量 (克)
  double getTotalWeight();

  /// 計算已打包重量 (克)
  double getCheckedWeight();

  /// 依分類統計重量
  Map<String, double> getWeightByCategory();

  // ========== Watch ==========

  /// 監聽裝備變更
  Stream<BoxEvent> watchAllItems();
}
