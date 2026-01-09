import '../../models/itinerary_item.dart';

abstract class IItineraryRemoteDataSource {
  /// 取得雲端行程節點列表 (透過 sync/getAll API)
  Future<List<ItineraryItem>> fetchItinerary(String tripId);
}
