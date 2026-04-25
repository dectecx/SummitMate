import 'package:injectable/injectable.dart';
import '../../models/meal_item.dart';
import '../../api/mappers/trip_meal_api_mapper.dart';
import '../../api/services/trip_meal_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_trip_meal_remote_data_source.dart';

/// 行程餐飲 (Trip Meal) 的遠端資料來源實作
@LazySingleton(as: ITripMealRemoteDataSource)
class TripMealRemoteDataSource implements ITripMealRemoteDataSource {
  static const String _source = 'TripMealRemoteDataSource';

  final TripMealApiService _tripMealApi;

  TripMealRemoteDataSource(this._tripMealApi);

  @override
  Future<List<MealItem>> getTripMeals(String tripId) async {
    try {
      LogService.info('取得行程餐點清單: $tripId', source: _source);
      final responses = await _tripMealApi.listMeals(tripId);
      return responses.map(TripMealApiMapper.fromResponse).toList();
    } catch (e) {
      LogService.error('getTripMeals 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<MealItem> addTripMeal(
    String tripId,
    MealItem item, {
    required String day,
    required String mealType,
  }) async {
    try {
      LogService.info('新增餐點至行程: $tripId', source: _source);
      final request = TripMealApiMapper.toRequest(item, day: day, mealType: mealType);
      final response = await _tripMealApi.addMeal(tripId, request);
      return TripMealApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('addTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<MealItem> updateTripMeal(
    String tripId,
    MealItem item, {
    required String day,
    required String mealType,
  }) async {
    try {
      LogService.info('更新餐點: $tripId, 項目: ${item.id}', source: _source);
      final request = TripMealApiMapper.toRequest(item, day: day, mealType: mealType);
      final response = await _tripMealApi.updateMeal(tripId, item.id, request);
      return TripMealApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('updateTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteTripMeal(String tripId, String itemId) async {
    try {
      LogService.info('刪除餐點: $tripId, 項目: $itemId', source: _source);
      await _tripMealApi.deleteMeal(tripId, itemId);
    } catch (e) {
      LogService.error('deleteTripMeal 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> replaceAllTripMeals(
    String tripId,
    List<({MealItem item, String day, String mealType})> requests,
  ) async {
    try {
      LogService.info('批量替換行程餐飲: $tripId, 數量: ${requests.length}', source: _source);
      await _tripMealApi.replaceAllMeals(
        tripId,
        requests
            .map((r) => TripMealApiMapper.toRequest(r.item, day: r.day, mealType: r.mealType))
            .toList(),
      );
    } catch (e) {
      LogService.error('replaceAllTripMeals 失敗: $e', source: _source);
      rethrow;
    }
  }
}
