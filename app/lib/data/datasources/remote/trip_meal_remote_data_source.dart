import '../../../core/di.dart';
import '../../models/meal_item.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';

/// 行程餐飲 (Trip Meal) 的遠端資料來源介面
abstract class ITripMealRemoteDataSource {
  /// 取得行程所有餐點
  Future<List<MealItem>> getTripMeals(String tripId);

  /// 新增餐點至行程
  Future<MealItem> addTripMeal(String tripId, MealItem item);

  /// 更新行程餐點內容
  Future<void> updateTripMeal(String tripId, MealItem item);

  /// 從行程中刪除餐點
  Future<void> deleteTripMeal(String tripId, String itemId);

  /// 批量替換行程所有餐點
  Future<void> replaceAllTripMeals(String tripId, List<MealItem> items);
}

/// 行程餐飲 (Trip Meal) 的遠端資料來源實作
class TripMealRemoteDataSource implements ITripMealRemoteDataSource {
  static const String _source = 'TripMealRemoteDataSource';
  final NetworkAwareClient _apiClient;

  TripMealRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得行程餐點清單
  ///
  /// [tripId] 行程 ID
  @override
  Future<List<MealItem>> getTripMeals(String tripId) async {
    try {
      LogService.info('取得行程餐點清單: $tripId', source: _source);
      final response = await _apiClient.get('/trips/$tripId/meals');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('getTripMeals 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 新增餐點
  ///
  /// [tripId] 行程 ID
  /// [item] 餐點資料模型
  @override
  Future<MealItem> addTripMeal(String tripId, MealItem item) async {
    try {
      LogService.info('新增餐點至行程: $tripId', source: _source);
      final response = await _apiClient.post('/trips/$tripId/meals', data: item.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return MealItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('addTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 更新餐點
  ///
  /// [tripId] 行程 ID
  /// [item] 餐點資料模型 (含 id)
  @override
  Future<void> updateTripMeal(String tripId, MealItem item) async {
    try {
      LogService.info('更新餐點: $tripId, 項目: ${item.id}', source: _source);
      final response = await _apiClient.put('/trips/$tripId/meals/${item.id}', data: item.toJson());

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('updateTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 刪除餐點
  ///
  /// [tripId] 行程 ID
  /// [itemId] 餐點 ID
  @override
  Future<void> deleteTripMeal(String tripId, String itemId) async {
    try {
      LogService.info('刪除餐點: $tripId, 項目: $itemId', source: _source);
      final response = await _apiClient.delete('/trips/$tripId/meals/$itemId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  /// 批量替換清單
  ///
  /// [tripId] 行程 ID
  /// [items] 新清單
  @override
  Future<void> replaceAllTripMeals(String tripId, List<MealItem> items) async {
    try {
      LogService.info('批量替換行程餐飲: $tripId', source: _source);

      final response = await _apiClient.put('/trips/$tripId/meals', data: items.map((e) => e.toJson()).toList());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('replaceAllTripMeals 失敗: $e', source: _source);
      rethrow;
    }
  }
}
