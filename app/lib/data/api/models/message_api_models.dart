import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_api_models.freezed.dart';
part 'message_api_models.g.dart';

// ── Response ──

/// 留言回應（對應 Message schema）
@freezed
abstract class MessageResponse with _$MessageResponse {
  const factory MessageResponse({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name', defaultValue: '') required String displayName,
    @JsonKey(defaultValue: '🐻') String? avatar,
    @JsonKey(defaultValue: '') required String category,
    @JsonKey(defaultValue: '') required String content,
    required DateTime timestamp,
    List<MessageResponse>? replies,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MessageResponse;

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);
}

// ── Request ──

/// 建立/更新留言請求（對應 MessageRequest schema）
@freezed
abstract class MessageCreateRequest with _$MessageCreateRequest {
  const factory MessageCreateRequest({
    required String content,
    String? category,
    @JsonKey(name: 'parent_id') String? parentId,
  }) = _MessageCreateRequest;

  factory MessageCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageCreateRequestFromJson(json);
}
