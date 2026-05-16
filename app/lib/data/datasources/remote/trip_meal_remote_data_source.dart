import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/domain/entities/meal_plan_day.dart';
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

  // ========== Meal Plan Day Management ==========

  @override
  Future<List<MealPlanDay>> getMealPlanDays(String tripId) async {
    try {
      LogService.info('取得糧食計畫天數: $tripId', source: _source);
      final responses = await _tripMealApi.listMealPlanDays(tripId);
      return responses.map(TripMealApiMapper.fromDayResponse).toList();
    } catch (e) {
      LogService.error('getMealPlanDays 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<MealPlanDay> addMealPlanDay(String tripId, String name, {String? linkedItineraryDay}) async {
    try {
      LogService.info('新增糧食計畫天數: $tripId, 名稱: $name', source: _source);
      final request = TripMealApiMapper.toDayRequest(name, linkedItineraryDay: linkedItineraryDay);
      final response = await _tripMealApi.addMealPlanDay(tripId, request);
      return TripMealApiMapper.fromDayResponse(response);
    } catch (e) {
      LogService.error('addMealPlanDay 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<MealPlanDay> updateMealPlanDay(String tripId, String dayId, String name, {String? linkedItineraryDay}) async {
    try {
      LogService.info('更新糧食計畫天數: $tripId, dayId: $dayId, 名稱: $name', source: _source);
      final request = TripMealApiMapper.toDayRequest(name, linkedItineraryDay: linkedItineraryDay);
      final response = await _tripMealApi.updateMealPlanDay(tripId, dayId, request);
      return TripMealApiMapper.fromDayResponse(response);
    } catch (e) {
      LogService.error('updateMealPlanDay 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteMealPlanDay(String tripId, String dayId) async {
    try {
      LogService.info('刪除糧食計畫天數: $tripId, dayId: $dayId', source: _source);
      await _tripMealApi.deleteMealPlanDay(tripId, dayId);
    } catch (e) {
      LogService.error('deleteMealPlanDay 失敗: $e', source: _source);
      rethrow;
    }
  }

  // ========== Meal Item Operations ==========

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
    required String mealPlanDayId,
    required String mealType,
  }) async {
    try {
      LogService.info('新增餐點至行程: $tripId', source: _source);
      final request = TripMealApiMapper.toRequest(item, mealPlanDayId: mealPlanDayId, mealType: mealType);
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
    required String mealPlanDayId,
    required String mealType,
  }) async {
    try {
      LogService.info('更新餐點: $tripId, 項目: ${item.id}', source: _source);
      final request = TripMealApiMapper.toRequest(item, mealPlanDayId: mealPlanDayId, mealType: mealType);
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
}
