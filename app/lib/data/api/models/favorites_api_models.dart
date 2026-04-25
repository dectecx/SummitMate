import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorites_api_models.freezed.dart';
part 'favorites_api_models.g.dart';

// ── Response ──

/// 最愛回應（對應 Favorite schema）
@freezed
class FavoriteResponse with _$FavoriteResponse {
  const factory FavoriteResponse({
    required String id,
    @JsonKey(name: 'target_id') required String targetId,
    required String type,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'updated_by') required String updatedBy,
  }) = _FavoriteResponse;

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResponseFromJson(json);
}

// ── Requests ──

/// 新增最愛請求（對應 FavoriteRequest schema）
@freezed
class FavoriteAddRequest with _$FavoriteAddRequest {
  const factory FavoriteAddRequest({
    @JsonKey(name: 'target_id') required String targetId,
    required String type,
  }) = _FavoriteAddRequest;

  factory FavoriteAddRequest.fromJson(Map<String, dynamic> json) =>
      _$FavoriteAddRequestFromJson(json);
}

/// 批量更新最愛請求項目（對應 BatchFavoriteRequest schema）
@freezed
class BatchFavoriteItem with _$BatchFavoriteItem {
  const factory BatchFavoriteItem({
    @JsonKey(name: 'target_id') required String targetId,
    required String type,
    @JsonKey(name: 'is_favorite') required bool isFavorite,
  }) = _BatchFavoriteItem;

  factory BatchFavoriteItem.fromJson(Map<String, dynamic> json) =>
      _$BatchFavoriteItemFromJson(json);
}
