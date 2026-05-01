import '../../../domain/entities/itinerary_item.dart';
import '../../models/itinerary_item_model.dart';

/// 行程項目 (ItineraryItemModel) 的遠端資料來源介面
///
/// 負責定義與後端 API 進行行程資料交換的操作。
abstract interface class IItineraryRemoteDataSource {
  /// 取得雲端行程節點列表 (透過 sync/getAll API)
  ///
  /// [tripId] 指定的行程 ID
  /// [tripId] 指定的行程 ID
  Future<List<ItineraryItemModel>> getItinerary(String tripId);

  /// 新增行程節點
  Future<ItineraryItemModel> addItem(String tripId, ItineraryItem item);

  /// 更新行程節點
  Future<ItineraryItemModel> updateItem(String tripId, ItineraryItem item);

  /// 刪除行程節點
  Future<void> deleteItem(String tripId, String itemId);
}
