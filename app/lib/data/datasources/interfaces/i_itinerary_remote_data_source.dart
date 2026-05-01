import '../../../domain/entities/itinerary_item.dart';

/// 行程項目 (ItineraryItem) 的遠端資料來源介面
///
/// 負責定義與後端 API 進行行程資料交換的操作。
abstract interface class IItineraryRemoteDataSource {
  /// 取得雲端行程節點列表 (透過 sync/getAll API)
  ///
  /// [tripId] 指定的行程 ID
  Future<List<ItineraryItem>> getItinerary(String tripId);

  /// 新增行程節點
  Future<ItineraryItem> addItem(String tripId, ItineraryItem item);

  /// 更新行程節點
  Future<ItineraryItem> updateItem(String tripId, ItineraryItem item);

  /// 刪除行程節點
  Future<void> deleteItem(String tripId, String itemId);
}
