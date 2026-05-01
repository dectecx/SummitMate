import '../../../domain/entities/group_event.dart';
import '../../models/group_event_comment.dart';
import '../../models/enums/group_event_status.dart';
import '../../models/enums/group_event_application_status.dart';
import '../../models/trip_snapshot.dart';
import 'itinerary_api_mapper.dart';
import '../models/group_event_api_models.dart';

/// GroupEvent API Model ↔ Domain Model 轉換
class GroupEventApiMapper {
  /// GroupEventResponse → GroupEvent (domain model)
  static GroupEvent fromResponse(GroupEventResponse response) {
    return GroupEvent(
      id: response.id,
      creatorId: response.creatorId,
      title: response.title,
      description: response.description,
      category: response.category,
      location: response.location,
      startDate: response.startDate.toLocal(),
      endDate: response.endDate?.toLocal(),
      status: _parseStatus(response.status),
      maxMembers: response.maxMembers,
      applicationCount: response.applicationCount,
      totalApplicationCount: response.totalApplicationCount,
      approvalRequired: response.approvalRequired,
      privateMessage: response.privateMessage,
      linkedTripId: response.linkedTripId,
      tripSnapshot: response.tripSnapshot != null ? fromSnapshotResponse(response.tripSnapshot!) : null,
      snapshotUpdatedAt: response.snapshotUpdatedAt?.toLocal(),
      likeCount: response.likeCount,
      commentCount: response.commentCount,
      isLiked: response.isLiked,
      myApplicationStatus: response.myApplicationStatus != null
          ? _parseApplicationStatus(response.myApplicationStatus!)
          : null,
      creatorName: response.creatorName,
      creatorAvatar: response.creatorAvatar,
      latestComments: response.latestComments.map(fromCommentResponse).toList(),
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// GroupEventApplicationResponse → GroupEventApplication (domain model)
  static GroupEventApplication fromApplicationResponse(GroupEventApplicationResponse response) {
    return GroupEventApplication(
      id: response.id,
      eventId: response.eventId,
      userId: response.userId,
      status: _parseApplicationStatus(response.status),
      message: response.message,
      userName: response.userName,
      userAvatar: response.userAvatar,
      createdAt: response.createdAt.toLocal(),
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// GroupEventCommentResponse → GroupEventComment (domain model)
  static GroupEventComment fromCommentResponse(GroupEventCommentResponse response) {
    return GroupEventComment(
      id: response.id,
      eventId: response.eventId,
      userId: response.userId,
      content: response.content,
      userName: response.userName,
      userAvatar: response.userAvatar,
      createdAt: response.createdAt.toLocal(),
      updatedAt: response.updatedAt.toLocal(),
    );
  }

  /// TripSnapshotResponse → TripSnapshot (domain model)
  static TripSnapshot fromSnapshotResponse(TripSnapshotResponse response) {
    return TripSnapshot(
      name: response.name,
      startDate: response.startDate.toLocal(),
      endDate: response.endDate?.toLocal(),
      itinerary: response.itinerary.map(ItineraryApiMapper.fromResponse).toList(),
    );
  }

  static GroupEventStatus _parseStatus(String value) {
    return GroupEventStatus.values.firstWhere((e) => e.name == value, orElse: () => GroupEventStatus.open);
  }

  static GroupEventApplicationStatus _parseApplicationStatus(String value) {
    return GroupEventApplicationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GroupEventApplicationStatus.pending,
    );
  }
}
