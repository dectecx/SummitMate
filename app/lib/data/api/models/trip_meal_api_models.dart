import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_meal_api_models.freezed.dart';
part 'trip_meal_api_models.g.dart';

// ── Response ──

/// 行程餐點項目回應（對應 TripMealItem schema）
@freezed
abstract class TripMealItemResponse with _$TripMealItemResponse {
  const factory TripMealItemResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'library_item_id') String? libraryItemId,
    required String day,
    @JsonKey(name: 'meal_type') required String mealType,
    required String name,
    @JsonKey(defaultValue: 0.0) required double weight,
    @JsonKey(defaultValue: 0.0) required double calories,
    @JsonKey(defaultValue: 1) required int quantity,
    String? note,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TripMealItemResponse;

  factory TripMealItemResponse.fromJson(Map<String, dynamic> json) => _$TripMealItemResponseFromJson(json);
}

// ── Requests ──

/// 新增/更新行程餐點請求（對應 TripMealItemRequest schema）
@freezed
abstract class TripMealItemRequest with _$TripMealItemRequest {
  const factory TripMealItemRequest({
    @JsonKey(name: 'library_item_id') String? libraryItemId,
    required String day,
    @JsonKey(name: 'meal_type') required String mealType,
    required String name,
    required double weight,
    required double calories,
    @JsonKey(defaultValue: 1) required int quantity,
    String? note,
  }) = _TripMealItemRequest;

  factory TripMealItemRequest.fromJson(Map<String, dynamic> json) => _$TripMealItemRequestFromJson(json);
}
