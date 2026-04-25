import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_gear_api_models.freezed.dart';
part 'trip_gear_api_models.g.dart';

// ── Response ──

/// 行程裝備項目回應（對應 TripGearItem schema）
@freezed
abstract class TripGearItemResponse with _$TripGearItemResponse {
  const factory TripGearItemResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'library_item_id') String? libraryItemId,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: 0.0) required double weight,
    @JsonKey(defaultValue: 'Other') required String category,
    @JsonKey(defaultValue: 1) required int quantity,
    @JsonKey(name: 'is_checked', defaultValue: false) required bool isChecked,
    @JsonKey(name: 'order_index') int? orderIndex,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TripGearItemResponse;

  factory TripGearItemResponse.fromJson(Map<String, dynamic> json) =>
      _$TripGearItemResponseFromJson(json);
}

// ── Requests ──

/// 新增/更新行程裝備請求（對應 TripGearItemRequest schema）
@freezed
abstract class TripGearItemRequest with _$TripGearItemRequest {
  const factory TripGearItemRequest({
    @JsonKey(name: 'library_item_id') String? libraryItemId,
    required String name,
    required double weight,
    required String category,
    @JsonKey(defaultValue: 1) required int quantity,
    @JsonKey(name: 'is_checked', defaultValue: false) required bool isChecked,
    @JsonKey(name: 'order_index') int? orderIndex,
  }) = _TripGearItemRequest;

  factory TripGearItemRequest.fromJson(Map<String, dynamic> json) =>
      _$TripGearItemRequestFromJson(json);
}
