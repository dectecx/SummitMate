import 'package:hive/hive.dart';
import '../../models/gear_item.dart';

/// Gear Repository 抽象介面
/// 定義裝備資料存取的契約
abstract interface class IGearRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得所有裝備 (依 orderIndex 排序)
  List<GearItem> getAllItems();

  /// 依分類取得裝備
  ///
  /// [category] 裝備分類
  List<GearItem> getItemsByCategory(String category);

  /// 取得未打包的裝備
  List<GearItem> getUncheckedItems();

  /// 新增裝備
  ///
  /// [item] 欲新增的裝備
  /// 回傳: 新增項目的 Key
  Future<int> addItem(GearItem item);

  /// 更新裝備
  ///
  /// [item] 更新後的裝備
  Future<void> updateItem(GearItem item);

  /// 刪除裝備
  ///
  /// [key] 裝備的本地鍵值
  Future<void> deleteItem(dynamic key);

  /// 切換打包狀態
  ///
  /// [key] 裝備的本地鍵值
  Future<void> toggleChecked(dynamic key);

  /// 計算總重量 (克)
  double getTotalWeight();

  /// 計算已打包重量 (克)
  double getCheckedWeight();

  /// 依分類統計重量
  Map<String, double> getWeightByCategory();

  /// 監聽裝備變更
  Stream<BoxEvent> watchAllItems();

  /// 重置所有打包狀態
  Future<void> resetAllChecked();

  /// 批量更新裝備順序
  ///
  /// [items] 重新排序後的裝備列表
  Future<void> updateItemsOrder(List<GearItem> items);

  /// 清除指定行程的所有裝備
  ///
  /// [tripId] 行程 ID
  Future<void> clearByTripId(String tripId);

  /// 清除所有裝備 (Debug 用途)
  Future<void> clearAll();
}
