import '../../../domain/entities/gear_item.dart';

/// 裝備項目 (GearItem) 的本地資料來源介面
abstract interface class IGearLocalDataSource {
  /// 取得所有裝備項目
  Future<List<GearItem>> getAll();

  /// 根據行程 ID 取得裝備清單
  Future<List<GearItem>> getByTripId(String tripId);

  /// 根據類別取得裝備清單
  Future<List<GearItem>> getByCategory(String category);

  /// 取得尚未檢查 (checkbox 未勾選) 的裝備
  Future<List<GearItem>> getUnchecked();

  /// 透過 Key 取得單一裝備 (已廢棄，僅供遷移參考)
  GearItem? getByKey(dynamic key);

  /// 透過 ID 取得單一裝備 (UUID)
  Future<GearItem?> getById(String id);

  /// 新增裝備項目
  Future<int> addItem(GearItem item);

  /// 更新裝備項目
  Future<void> updateItem(GearItem item);

  /// 刪除裝備項目 (透過 Key，已廢棄)
  Future<void> deleteByKey(dynamic key);

  /// 刪除裝備項目 (透過 ID)
  Future<void> deleteById(String id);

  /// 清除指定行程的所有裝備
  Future<void> clearByTripId(String tripId);

  /// 清除所有裝備資料
  Future<void> clearAll();

  /// 監聽資料變更流
  Stream<List<GearItem>> watch();
}
