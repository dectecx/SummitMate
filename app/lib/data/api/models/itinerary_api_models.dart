import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_api_models.freezed.dart';
part 'itinerary_api_models.g.dart';

// ── Response ──

/// 行程節點回應（對應 ItineraryItemListItemResponse schema）
@freezed
class ItineraryItemResponse with _$ItineraryItemResponse {
  const factory ItineraryItemResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(defaultValue: '') required String day,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(name: 'est_time', defaultValue: '') required String estTime,
    @JsonKey(name: 'actual_time') DateTime? actualTime,
    @JsonKey(defaultValue: 0) required int altitude,
    @JsonKey(defaultValue: 0.0) required double distance,
    @JsonKey(defaultValue: '') required String note,
    @JsonKey(name: 'image_asset') String? imageAsset,
    @JsonKey(name: 'is_checked_in', defaultValue: false) required bool isCheckedIn,
    @JsonKey(name: 'checked_in_at') DateTime? checkedInAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ItineraryItemResponse;

  factory ItineraryItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemResponseFromJson(json);
}

// ── Request ──

/// 行程節點建立/更新請求（對應 ItineraryItemRequest schema）
@freezed
class ItineraryItemRequest with _$ItineraryItemRequest {
  const factory ItineraryItemRequest({
    required String day,
    required String name,
    @JsonKey(name: 'est_time') required String estTime,
    int? altitude,
    double? distance,
    String? note,
    @JsonKey(name: 'image_asset') String? imageAsset,
  }) = _ItineraryItemRequest;

  factory ItineraryItemRequest.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemRequestFromJson(json);
}
