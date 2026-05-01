import 'package:summitmate/domain/domain.dart';
import '../models/message_api_models.dart';

/// Message API Model ↔ Domain Model 轉換
class MessageApiMapper {
  /// MessageResponse → Message (domain model)
  static Message fromResponse(MessageResponse response) {
    return Message(
      id: response.id,
      tripId: response.tripId,
      parentId: response.parentId,
      userId: response.userId,
      user: response.displayName,
      avatar: response.avatar ?? '🐻',
      category: response.category,
      content: response.content,
      timestamp: response.timestamp.toLocal(),
      createdAt: response.createdAt.toLocal(),
      createdBy: response.userId,
      updatedAt: response.updatedAt?.toLocal() ?? response.createdAt.toLocal(),
      updatedBy: response.userId,
    );
  }

  /// Message (domain model) → MessageCreateRequest
  static MessageCreateRequest toCreateRequest(String content, [String? parentId, String? category]) {
    return MessageCreateRequest(content: content, category: category, parentId: parentId);
  }
}
