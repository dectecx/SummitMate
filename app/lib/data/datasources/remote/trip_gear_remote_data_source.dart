import 'package:injectable/injectable.dart';
import '../../../core/di/injection.dart';
import '../../models/gear_item.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';

/// 行程裝備 (Trip Gear) 的遠端資料來源介面
abstract class ITripGearRemoteDataSource {
  /// 取得行程裝備清單
  Future<List<GearItem>> getTripGear(String tripId);

  /// 新增裝備至行程
  Future<GearItem> addTripGear(String tripId, GearItem item);

  /// 更新行程裝備內容
  Future<void> updateTripGear(String tripId, GearItem item);

  /// 從行程中刪除裝備
  Future<void> deleteTripGear(String tripId, String itemId);

  /// 批量替換行程所有裝備
  Future<void> replaceAllTripGear(String tripId, List<GearItem> items);
}

/// 行程裝備 (Trip Gear) 的遠端資料來源實作
class TripGearRemoteDataSource implements ITripGearRemoteDataSource {
  static const String _source = 'TripGearRemoteDataSource';
  final NetworkAwareClient _apiClient;

  TripGearRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得行程裝備清單
  ///
  /// [tripId] 行程 ID
  @override
  Future<List<GearItem>> getTripGear(String tripId) async {
    try {
      LogService.info('取得行程裝備清單: $tripId', source: _source);
      final response = await _apiClient.get('/trips/$tripId/gear');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => GearItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('getTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 新增單項裝備至行程
  ///
  /// [tripId] 行程 ID
  /// [item] 裝備項
  @override
  Future<GearItem> addTripGear(String tripId, GearItem item) async {
    try {
      LogService.info('新增裝備至行程: $tripId, 名稱: ${item.name}', source: _source);
      final response = await _apiClient.post('/trips/$tripId/gear', data: item.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GearItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('addTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 更新行程中的單項裝備
  ///
  /// [tripId] 行程 ID
  /// [item] 欲更新的裝備項 (需含 uuid)
  @override
  Future<void> updateTripGear(String tripId, GearItem item) async {
    try {
      LogService.info('更新裝備: $tripId, 項目: ${item.uuid}', source: _source);
      final response = await _apiClient.put('/trips/$tripId/gear/${item.uuid}', data: item.toJson());

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('updateTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除行程中的裝備
  ///
  /// [tripId] 行程 ID
  /// [itemId] 裝備 ID (uuid)
  @override
  Future<void> deleteTripGear(String tripId, String itemId) async {
    try {
      LogService.info('刪除裝備: $tripId, 項目: $itemId', source: _source);
      final response = await _apiClient.delete('/trips/$tripId/gear/$itemId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 批量替換行程所有裝備
  ///
  /// [tripId] 行程 ID
  /// [items] 新的裝備清單
  @override
  Future<void> replaceAllTripGear(String tripId, List<GearItem> items) async {
    try {
      LogService.info('批量替換行程裝備: $tripId, 數量: ${items.length}', source: _source);

      final response = await _apiClient.put('/trips/$tripId/gear', data: items.map((e) => e.toJson()).toList());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('replaceAllTripGear 失敗: $e', source: _source);
      rethrow;
    }
  }
}
