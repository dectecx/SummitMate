import 'package:injectable/injectable.dart';
import '../../models/itinerary_item.dart';
import '../../api/services/itinerary_api_service.dart';
import '../../api/mappers/itinerary_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_itinerary_remote_data_source.dart';

/// 行程項目 (ItineraryItem) 的遠端資料來源實作
@LazySingleton(as: IItineraryRemoteDataSource)
class ItineraryRemoteDataSource implements IItineraryRemoteDataSource {
  static const String _source = 'ItineraryRemoteDataSource';

  final ItineraryApiService _itineraryApi;

  ItineraryRemoteDataSource(this._itineraryApi);

  @override
  Future<List<ItineraryItem>> getItinerary(String tripId) async {
    try {
      LogService.info('獲取行程節點列表: $tripId', source: _source);
      final responses = await _itineraryApi.listItinerary(tripId);
      final items = responses.map(ItineraryApiMapper.fromResponse).toList();
      LogService.debug('已獲取 ${items.length} 個行程節點', source: _source);
      return items;
    } catch (e) {
      LogService.error('getItinerary 失敗: $e', source: _source);
      rethrow;
    }
  }
}
