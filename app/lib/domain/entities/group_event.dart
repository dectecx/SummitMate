import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../data/models/enums/group_event_application_status.dart';
import '../../data/models/enums/group_event_category.dart';
import 'group_event_comment.dart';
import 'trip_snapshot.dart';

part 'group_event.freezed.dart';

/// 揪團活動領域實體 (Domain Entity)
@freezed
abstract class GroupEvent with _$GroupEvent {
  const GroupEvent._();

  const factory GroupEvent({
    required String id,
    required String creatorId,
    required String title,
    @Default('') String description,
    @Default(GroupEventCategory.other) GroupEventCategory category,
    @Default('') String location,
    required DateTime startDate,
    DateTime? endDate,
    @Default(GroupEventStatus.open) GroupEventStatus status,
    @Default(10) int maxMembers,
    @Default(0) int applicationCount,
    @Default(0) int totalApplicationCount,
    @Default(false) bool approvalRequired,
    @Default('') String privateMessage,
    String? linkedTripId,
    TripSnapshot? tripSnapshot,
    DateTime? snapshotUpdatedAt,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool isLiked,
    GroupEventApplicationStatus? myApplicationStatus,
    @Default('') String creatorName,
    @Default('🐻') String creatorAvatar,
    @Default([]) List<GroupEventComment> latestComments,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _GroupEvent;

  bool get isOpen => status == GroupEventStatus.open;
  bool get isFull => applicationCount >= maxMembers;
  bool get canApply => isOpen;
  bool isCreator(String userId) => creatorId == userId;

  int get durationDays {
    if (endDate == null) return 1;
    final diff = endDate!.difference(startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }
}

/// 揪團報名紀錄領域實體 (Domain Entity)
@freezed
abstract class GroupEventApplication with _$GroupEventApplication {
  const GroupEventApplication._();

  const factory GroupEventApplication({
    required String id,
    required String eventId,
    required String userId,
    @Default(GroupEventApplicationStatus.pending) GroupEventApplicationStatus status,
    @Default('') String message,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedBy,
    @Default('') String userName,
    @Default('🐻') String userAvatar,
  }) = _GroupEventApplication;

  bool get isPending => status == GroupEventApplicationStatus.pending;
  bool get isApproved => status == GroupEventApplicationStatus.approved;
  bool get isRejected => status == GroupEventApplicationStatus.rejected;
}
