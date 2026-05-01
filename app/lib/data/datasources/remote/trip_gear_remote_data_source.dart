import 'package:injectable/injectable.dart';
import '../../../domain/entities/gear_item.dart';
import '../../models/gear_item_model.dart';
import '../../api/mappers/trip_gear_api_mapper.dart';
import '../../api/services/trip_gear_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_gear_remote_data_source.dart';

/// 行程裝備 (Trip Gear) 的遠端資料來源實作
@LazySingleton(as: ITripGearRemoteDataSource)
class TripGearRemoteDataSource implements ITripGearRemoteDataSource {
  static const String _source = 'TripGearRemoteDataSource';

  final TripGearApiService _tripGearApi;

  TripGearRemoteDataSource(this._tripGearApi);

  @override
  Future<List<GearItem>> getTripGear(String tripId) async {
    try {
      LogService.info('取得行程裝備清單: $tripId', source: _source);
      final responses = await _tripGearApi.listGear(tripId);
      return responses.map((r) => TripGearApiMapper.fromResponse(r).toDomain()).toList();
    } catch (e) {
      LogService.error('getTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GearItem> addTripGear(String tripId, GearItem item) async {
    try {
      LogService.info('新增裝備至行程: $tripId, 名稱: ${item.name}', source: _source);
      final request = TripGearApiMapper.toRequest(item);
      final response = await _tripGearApi.addGear(tripId, request);
      return TripGearApiMapper.fromResponse(response).toDomain();
    } catch (e) {
      LogService.error('addTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GearItem> updateTripGear(String tripId, GearItem item) async {
    try {
      LogService.info('更新裝備: $tripId, 項目: ${item.id}', source: _source);
      final request = TripGearApiMapper.toRequest(item);
      final response = await _tripGearApi.updateGear(tripId, item.id, request);
      return TripGearApiMapper.fromResponse(response).toDomain();
    } catch (e) {
      LogService.error('updateTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteTripGear(String tripId, String itemId) async {
    try {
      LogService.info('刪除裝備: $tripId, 項目: $itemId', source: _source);
      await _tripGearApi.deleteGear(tripId, itemId);
    } catch (e) {
      LogService.error('deleteTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> replaceAllTripGear(String tripId, List<GearItem> items) async {
    try {
      LogService.info('批量替換行程裝備: $tripId, 數量: ${items.length}', source: _source);
      await _tripGearApi.replaceAllGear(tripId, items.map(TripGearApiMapper.toRequest).toList());
    } catch (e) {
      LogService.error('replaceAllTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }
}
