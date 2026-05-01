import 'package:injectable/injectable.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../../models/itinerary_item_model.dart';
import '../../api/services/itinerary_api_service.dart';
import '../../api/mappers/itinerary_api_mapper.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_itinerary_remote_data_source.dart';

/// 行程項目 (ItineraryItemModel) 的遠端資料來源實作
@LazySingleton(as: IItineraryRemoteDataSource)
class ItineraryRemoteDataSource implements IItineraryRemoteDataSource {
  static const String _source = 'ItineraryRemoteDataSource';

  final ItineraryApiService _itineraryApi;

  ItineraryRemoteDataSource(this._itineraryApi);

  @override
  Future<List<ItineraryItemModel>> getItinerary(String tripId) async {
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

  @override
  Future<ItineraryItemModel> addItem(String tripId, ItineraryItem item) async {
    try {
      LogService.info('新增行程節點: $tripId, 名稱: ${item.name}', source: _source);
      final request = ItineraryApiMapper.toRequest(item);
      final response = await _itineraryApi.addItem(tripId, request);
      return ItineraryApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('addItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<ItineraryItemModel> updateItem(String tripId, ItineraryItem item) async {
    try {
      LogService.info('更新行程節點: $tripId, 項目: ${item.id}', source: _source);
      final request = ItineraryApiMapper.toRequest(item);
      final response = await _itineraryApi.updateItem(tripId, item.id, request);
      return ItineraryApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('updateItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String tripId, String itemId) async {
    try {
      LogService.info('刪除行程節點: $tripId, 項目: $itemId', source: _source);
      await _itineraryApi.deleteItem(tripId, itemId);
    } catch (e) {
      LogService.error('deleteItem 失敗: $e', source: _source);
      rethrow;
    }
  }
}
