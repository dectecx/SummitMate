import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_library_api_models.freezed.dart';
part 'gear_library_api_models.g.dart';

// ── Request ──

/// 新增/更新裝備庫項目請求（對應 GearLibraryItemRequest schema）
@freezed
abstract class GearLibraryItemRequest with _$GearLibraryItemRequest {
  const factory GearLibraryItemRequest({
    required String name,
    required double weight,
    required String category,
    String? notes,
    @JsonKey(name: 'is_archived', defaultValue: false) bool? isArchived,
  }) = _GearLibraryItemRequest;

  factory GearLibraryItemRequest.fromJson(Map<String, dynamic> json) =>
      _$GearLibraryItemRequestFromJson(json);
}
