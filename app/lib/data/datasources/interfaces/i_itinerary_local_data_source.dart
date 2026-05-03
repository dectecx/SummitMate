import '../../../domain/entities/itinerary_item.dart';

/// 行程項目 (ItineraryItem) 的本地資料來源介面
abstract interface class IItineraryLocalDataSource {
  /// 取得所有行程項目
  Future<List<ItineraryItem>> getAll();

  /// 根據行程 ID 取得項目
  Future<List<ItineraryItem>> getByTripId(String tripId);

  /// 透過 ID 取得單一行程項目 (UUID)
  Future<ItineraryItem?> getById(String id);

  /// 新增行程項目
  Future<void> addItem(ItineraryItem item);

  /// 更新行程項目
  Future<void> updateItem(ItineraryItem item);

  /// 刪除行程項目 (透過 ID)
  Future<void> deleteById(String id);

  /// 清除指定行程的所有項目
  Future<void> clearByTripId(String tripId);

  /// 清除所有行程項目
  Future<void> clear();

  /// 監聽資料變更流
  Stream<List<ItineraryItem>> watch();

  /// 儲存最後同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得最後同步時間
  Future<DateTime?> getLastSyncTime();
}
