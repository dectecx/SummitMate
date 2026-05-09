import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_set_api_models.freezed.dart';
part 'gear_set_api_models.g.dart';

// ── Items & Meals ──

@freezed
abstract class GearSetItemDto with _$GearSetItemDto {
  const factory GearSetItemDto({
    required String id,
    required String name,
    required String category,
    required double weight,
    @Default(1) int quantity,
    @JsonKey(name: 'order_index') @Default(0) int orderIndex,
  }) = _GearSetItemDto;

  factory GearSetItemDto.fromJson(Map<String, dynamic> json) =>
      _$GearSetItemDtoFromJson(json);
}

@freezed
abstract class GearSetMealDto with _$GearSetMealDto {
  const factory GearSetMealDto({
    required String id,
    required String day,
    @JsonKey(name: 'meal_type') required String mealType,
    required String name,
    @Default(0.0) double calories,
    String? note,
  }) = _GearSetMealDto;

  factory GearSetMealDto.fromJson(Map<String, dynamic> json) =>
      _$GearSetMealDtoFromJson(json);
}

// ── Response ──

@freezed
abstract class GearSetResponse with _$GearSetResponse {
  const factory GearSetResponse({
    required String id,
    required String title,
    required String author,
    @JsonKey(name: 'total_weight') @Default(0.0) double totalWeight,
    @JsonKey(name: 'item_count') @Default(0) int itemCount,
    required String visibility,
    @JsonKey(name: 'download_key') String? downloadKey,
    @Default([]) List<GearSetItemDto> items,
    List<GearSetMealDto>? meals,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _GearSetResponse;

  factory GearSetResponse.fromJson(Map<String, dynamic> json) =>
      _$GearSetResponseFromJson(json);
}

@freezed
abstract class GearSetListResponse with _$GearSetListResponse {
  const factory GearSetListResponse({
    @Default([]) List<GearSetResponse> data,
  }) = _GearSetListResponse;

  factory GearSetListResponse.fromJson(Map<String, dynamic> json) =>
      _$GearSetListResponseFromJson(json);
}

// ── Request ──
// Note: items/meals use dynamic JSON since Freezed can't generate for Map<String,dynamic> lists.
// Serialization is handled manually in the mapper.

class GearSetCreateRequest {
  final String title;
  final String author;
  final String visibility;
  final String? downloadKey;
  final double totalWeight;
  final int itemCount;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>>? meals;

  const GearSetCreateRequest({
    required this.title,
    required this.author,
    required this.visibility,
    this.downloadKey,
    required this.totalWeight,
    required this.itemCount,
    this.items = const [],
    this.meals,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'visibility': visibility,
        if (downloadKey != null) 'download_key': downloadKey,
        'total_weight': totalWeight,
        'item_count': itemCount,
        'items': items,
        if (meals != null) 'meals': meals,
      };
}
