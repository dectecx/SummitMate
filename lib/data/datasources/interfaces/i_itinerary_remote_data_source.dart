import '../../models/itinerary_item.dart';

/// 行程項目 (ItineraryItem) 的遠端資料來源介面
///
/// 負責定義與後端 API (GAS) 進行行程資料交換的操作。
abstract class IItineraryRemoteDataSource {
  /// 取得雲端行程節點列表 (透過 sync/getAll API)
  ///
  /// [tripId] 指定的行程 ID
  Future<List<ItineraryItem>> getItinerary(String tripId);
}
