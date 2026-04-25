import 'package:freezed_annotation/freezed_annotation.dart';
import 'pagination_api_models.dart';

part 'gear_library_api_models.freezed.dart';
part 'gear_library_api_models.g.dart';

@freezed
abstract class GearLibraryPaginationResponse with _$GearLibraryPaginationResponse {
  const factory GearLibraryPaginationResponse({
    required List<GearLibraryItemResponse> items,
    required PaginationMetadata pagination,
  }) = _GearLibraryPaginationResponse;

  factory GearLibraryPaginationResponse.fromJson(Map<String, dynamic> json) => _$GearLibraryPaginationResponseFromJson(json);
}

// ── Response ──

/// 裝備庫項目回應（對應 GearLibraryItem schema）
@freezed
abstract class GearLibraryItemResponse with _$GearLibraryItemResponse {
  const factory GearLibraryItemResponse({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: 0.0) required double weight,
    @JsonKey(defaultValue: 'Other') required String category,
    String? notes,
    @JsonKey(name: 'is_archived', defaultValue: false) required bool isArchived,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _GearLibraryItemResponse;

  factory GearLibraryItemResponse.fromJson(Map<String, dynamic> json) => _$GearLibraryItemResponseFromJson(json);
}

// ── Requests ──

/// 新增/更新裝備庫項目請求（對應 GearLibraryItemRequest schema）
@freezed
abstract class GearLibraryItemRequest with _$GearLibraryItemRequest {
  const factory GearLibraryItemRequest({
    required String name,
    required double weight,
    required String category,
    String? notes,
    @JsonKey(name: 'is_archived', defaultValue: false) required bool isArchived,
  }) = _GearLibraryItemRequest;

  factory GearLibraryItemRequest.fromJson(Map<String, dynamic> json) => _$GearLibraryItemRequestFromJson(json);
}
