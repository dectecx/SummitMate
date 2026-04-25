import 'package:freezed_annotation/freezed_annotation.dart';
import 'pagination_api_models.dart';

part 'meal_library_api_models.freezed.dart';
part 'meal_library_api_models.g.dart';

@freezed
abstract class MealLibraryPaginationResponse with _$MealLibraryPaginationResponse {
  const factory MealLibraryPaginationResponse({
    required List<MealLibraryItem> items,
    required PaginationMetadata pagination,
  }) = _MealLibraryPaginationResponse;

  factory MealLibraryPaginationResponse.fromJson(Map<String, dynamic> json) => _$MealLibraryPaginationResponseFromJson(json);
}

@freezed
abstract class MealLibraryItem with _$MealLibraryItem {
  const factory MealLibraryItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    required double weight,
    required double calories,
    String? notes,
    @JsonKey(name: 'is_archived') required bool isArchived,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _MealLibraryItem;

  factory MealLibraryItem.fromJson(Map<String, dynamic> json) => _$MealLibraryItemFromJson(json);
}

@freezed
abstract class MealLibraryItemRequest with _$MealLibraryItemRequest {
  const factory MealLibraryItemRequest({
    required String name,
    required double weight,
    required double calories,
    String? notes,
    @JsonKey(name: 'is_archived') bool? isArchived,
  }) = _MealLibraryItemRequest;

  factory MealLibraryItemRequest.fromJson(Map<String, dynamic> json) => _$MealLibraryItemRequestFromJson(json);
}
