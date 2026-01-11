import '../../models/trip.dart';

/// 行程 (Trip) 的遠端資料來源介面
///
/// 負責定義與後端 API (GAS) 進行行程資料交換的操作。
abstract class ITripRemoteDataSource {
  /// 取得所有雲端行程列表
  Future<List<Trip>> getTrips();

  /// 上傳單一行程 (僅行程 Meta)
  Future<String> uploadTrip(Trip trip);

  /// 更新行程
  Future<void> updateTrip(Trip trip);

  /// 刪除行程
  Future<void> deleteTrip(String tripId);

  /// 完整上傳行程 (包含行程表與裝備)
  ///
  /// [trip] 行程本體
  /// [itineraryItems] 行程節點列表
  /// [gearItems] 裝備列表
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  });
}
