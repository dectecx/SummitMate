import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums/group_event_status.dart';
import 'enums/group_event_application_status.dart';
import 'enums/group_event_category.dart';

import 'group_event_comment.dart';
import 'trip_snapshot.dart';

part 'group_event.g.dart';

/// 揪團活動
@HiveType(typeId: 12)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupEvent {
  /// 揪團 ID (PK)
  @HiveField(0)
  final String id;

  /// 建立者 ID
  @HiveField(1)
  final String creatorId;

  /// 標題
  @HiveField(2)
  final String title;

  /// 描述
  @HiveField(3)
  @JsonKey(defaultValue: '')
  final String description;

  /// 分類
  @HiveField(4)
  @JsonKey(defaultValue: GroupEventCategory.other)
  final GroupEventCategory category;

  /// 地點
  @HiveField(5)
  @JsonKey(defaultValue: '')
  final String location;

  /// 開始日期
  @HiveField(6)
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  /// 結束日期
  @HiveField(7)
  @JsonKey(name: 'end_date')
  final DateTime? endDate;

  /// 狀態
  @HiveField(8)
  @JsonKey(defaultValue: GroupEventStatus.open)
  final GroupEventStatus status;

  /// 招募人數上限
  @HiveField(9)
  @JsonKey(defaultValue: 10, fromJson: _parseInt)
  final int maxMembers;

  /// 已報名人數 (計算欄位)
  @HiveField(10)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int applicationCount;

  /// 總報名人數 (含審核中)
  @HiveField(11)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int totalApplicationCount;

  /// 是否需審核
  @HiveField(12)
  @JsonKey(defaultValue: false)
  final bool approvalRequired;

  /// 報名成功訊息 (審核通過後顯示)
  @HiveField(13)
  @JsonKey(defaultValue: '')
  final String privateMessage;

  /// 關聯的行程 ID
  @HiveField(14)
  final String? linkedTripId;

  /// 行程快照 (唯讀)
  @HiveField(15)
  final TripSnapshot? tripSnapshot;

  /// 快照更新時間
  @HiveField(16)
  @JsonKey(name: 'snapshot_updated_at')
  final DateTime? snapshotUpdatedAt;

  /// 喜歡數量 (快取)
  @HiveField(17)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int likeCount;

  /// 留言數量 (快取)
  @HiveField(18)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int commentCount;

  /// 當前使用者是否已喜歡
  @HiveField(19)
  @JsonKey(defaultValue: false)
  final bool isLiked;

  /// 當前使用者報名狀態 (null=未報名)
  @HiveField(20)
  final GroupEventApplicationStatus? myApplicationStatus;

  /// 建立者資訊 (快照)
  @HiveField(21)
  @JsonKey(defaultValue: '')
  final String creatorName;

  @HiveField(22)
  @JsonKey(defaultValue: '🐻')
  final String creatorAvatar;

  /// 建立時間
  @HiveField(23)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 建立者 ID
  @HiveField(24)
  @JsonKey(name: 'created_by')
  final String createdBy;

  /// 更新時間
  @HiveField(25)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// 更新者 ID
  @HiveField(26)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  /// 最新留言 (Preview)
  @HiveField(27)
  @JsonKey(defaultValue: [])
  final List<GroupEventComment> latestComments;

  GroupEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description = '',
    this.category = GroupEventCategory.other,
    this.location = '',
    required this.startDate,
    this.endDate,
    this.status = GroupEventStatus.open,
    this.maxMembers = 10,
    this.applicationCount = 0,
    this.totalApplicationCount = 0,
    this.approvalRequired = false,
    this.privateMessage = '',
    this.linkedTripId,
    this.tripSnapshot,
    this.snapshotUpdatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.myApplicationStatus,
    this.creatorName = '',
    this.creatorAvatar = '🐻',
    this.latestComments = const [],
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// 是否開放報名
  bool get isOpen => status == GroupEventStatus.open;

  /// 是否已額滿 (前端不再強制阻擋，改以 isFull 提示，但 canApply 可放寬)
  bool get isFull => applicationCount >= maxMembers;

  /// 可報名 (開放中且未額滿 - isFull 只是顯示用，開放中即可報名)
  bool get canApply => isOpen; // && !isFull (已放寬)

  /// 是否為創建者
  bool isCreator(String userId) => creatorId == userId;

  /// 行程天數
  int get durationDays {
    if (endDate == null) return 1;
    final diff = endDate!.difference(startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory GroupEvent.fromJson(Map<String, dynamic> json) => _$GroupEventFromJson(json);
  Map<String, dynamic> toJson() => _$GroupEventToJson(this);

  GroupEvent copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    GroupEventCategory? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    GroupEventStatus? status,
    int? maxMembers,
    int? applicationCount,
    int? totalApplicationCount,
    bool? approvalRequired,
    String? privateMessage,
    String? linkedTripId,
    TripSnapshot? tripSnapshot,
    DateTime? snapshotUpdatedAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    GroupEventApplicationStatus? myApplicationStatus,
    String? creatorName,
    String? creatorAvatar,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    List<GroupEventComment>? latestComments,
  }) {
    return GroupEvent(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      maxMembers: maxMembers ?? this.maxMembers,
      applicationCount: applicationCount ?? this.applicationCount,
      totalApplicationCount: totalApplicationCount ?? this.totalApplicationCount,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      privateMessage: privateMessage ?? this.privateMessage,
      linkedTripId: linkedTripId ?? this.linkedTripId,
      tripSnapshot: tripSnapshot ?? this.tripSnapshot,
      snapshotUpdatedAt: snapshotUpdatedAt ?? this.snapshotUpdatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      myApplicationStatus: myApplicationStatus ?? this.myApplicationStatus,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      latestComments: latestComments ?? this.latestComments,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// 揪團報名紀錄
@HiveType(typeId: 13)
@JsonSerializable(fieldRename: FieldRename.snake)
class GroupEventApplication {
  /// 報名 ID (PK)
  @HiveField(0)
  final String id;

  /// 揪團 ID
  @HiveField(1)
  final String eventId;

  /// 報名者 ID
  @HiveField(2)
  final String userId;

  /// 狀態
  @HiveField(3)
  @JsonKey(defaultValue: GroupEventApplicationStatus.pending)
  final GroupEventApplicationStatus status;

  /// 報名留言
  @HiveField(4)
  @JsonKey(defaultValue: '')
  final String message;

  /// 建立時間
  @HiveField(5)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 更新時間
  @HiveField(6)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// 更新者
  @HiveField(7)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  /// 報名者資訊 (快照)
  @HiveField(8)
  @JsonKey(defaultValue: '')
  final String userName;

  @HiveField(9)
  @JsonKey(defaultValue: '🐻')
  final String userAvatar;

  GroupEventApplication({
    required this.id,
    required this.eventId,
    required this.userId,
    this.status = GroupEventApplicationStatus.pending,
    this.message = '',
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.userName = '',
    this.userAvatar = '🐻',
  });

  /// 是否待審核
  bool get isPending => status == GroupEventApplicationStatus.pending;

  /// 是否已通過
  bool get isApproved => status == GroupEventApplicationStatus.approved;

  /// 是否已拒絕
  bool get isRejected => status == GroupEventApplicationStatus.rejected;

  factory GroupEventApplication.fromJson(Map<String, dynamic> json) => _$GroupEventApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$GroupEventApplicationToJson(this);
}
