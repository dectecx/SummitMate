import 'package:freezed_annotation/freezed_annotation.dart';
import '../converters/datetime_converter.dart';

part 'trip_meal_api_models.freezed.dart';
part 'trip_meal_api_models.g.dart';

// ── Response ──

/// 糧食計畫天數回應
@freezed
abstract class MealPlanDayResponse with _$MealPlanDayResponse {
  const factory MealPlanDayResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    required String name,
    @JsonKey(name: 'linked_itinerary_day') String? linkedItineraryDay,
    @JsonKey(name: 'created_at') @DateTimeUtcConverter() required DateTime createdAt,
    @JsonKey(name: 'updated_at') @DateTimeUtcConverter() required DateTime updatedAt,
  }) = _MealPlanDayResponse;

  factory MealPlanDayResponse.fromJson(Map<String, dynamic> json) => _$MealPlanDayResponseFromJson(json);
}

/// 行程餐點項目回應
@freezed
abstract class TripMealItemResponse with _$TripMealItemResponse {
  const factory TripMealItemResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'meal_plan_day_id') required String mealPlanDayId,
    @JsonKey(name: 'meal_type') required String mealType,
    required String name,
    @JsonKey(defaultValue: 0.0) required double weight,
    @JsonKey(defaultValue: 0.0) required double calories,
    @JsonKey(defaultValue: 1) required int quantity,
    String? note,
    @JsonKey(name: 'created_at') @DateTimeUtcConverter() required DateTime createdAt,
    @JsonKey(name: 'updated_at') @DateTimeUtcConverter() required DateTime updatedAt,
  }) = _TripMealItemResponse;

  factory TripMealItemResponse.fromJson(Map<String, dynamic> json) => _$TripMealItemResponseFromJson(json);
}

// ── Requests ──

/// 糧食計畫天數請求
@freezed
abstract class MealPlanDayRequest with _$MealPlanDayRequest {
  const factory MealPlanDayRequest({
    required String name,
    @JsonKey(name: 'linked_itinerary_day') String? linkedItineraryDay,
  }) = _MealPlanDayRequest;

  factory MealPlanDayRequest.fromJson(Map<String, dynamic> json) => _$MealPlanDayRequestFromJson(json);
}

/// 新增/更新行程餐點請求
@freezed
abstract class TripMealItemRequest with _$TripMealItemRequest {
  const factory TripMealItemRequest({
    @JsonKey(name: 'meal_plan_day_id') required String mealPlanDayId,
    @JsonKey(name: 'meal_type') required String mealType,
    required String name,
    required double weight,
    required double calories,
    @JsonKey(defaultValue: 1) required int quantity,
    String? note,
  }) = _TripMealItemRequest;

  factory TripMealItemRequest.fromJson(Map<String, dynamic> json) => _$TripMealItemRequestFromJson(json);
}
