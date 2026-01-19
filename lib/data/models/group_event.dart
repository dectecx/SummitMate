import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums/group_event_status.dart';
import 'enums/group_event_application_status.dart';

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

  /// 地點
  @HiveField(4)
  @JsonKey(defaultValue: '')
  final String location;

  /// 開始日期
  @HiveField(5)
  final DateTime startDate;

  /// 結束日期
  @HiveField(6)
  final DateTime? endDate;

  /// 招募人數上限
  @HiveField(7)
  @JsonKey(defaultValue: 10, fromJson: _parseInt)
  final int maxMembers;

  /// 狀態
  @HiveField(8)
  @JsonKey(defaultValue: GroupEventStatus.open)
  final GroupEventStatus status;

  /// 是否需審核
  @HiveField(9)
  @JsonKey(defaultValue: false)
  final bool approvalRequired;

  /// 報名成功訊息 (審核通過後顯示)
  @HiveField(10)
  @JsonKey(defaultValue: '')
  final String privateMessage;

  /// 關聯的行程 ID (TODO: 整合行程)
  @HiveField(11)
  final String? linkedTripId;

  /// 喜歡數量 (快取)
  @HiveField(12)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int likeCount;

  /// 留言數量 (快取)
  @HiveField(13)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int commentCount;

  /// 已報名人數 (計算欄位)
  @HiveField(14)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int applicationCount;

  /// 建立時間
  @HiveField(15)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 建立者 ID
  @HiveField(16)
  @JsonKey(name: 'created_by')
  final String createdBy;

  /// 更新時間
  @HiveField(17)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// 更新者 ID
  @HiveField(18)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  /// 建立者資訊 (快照)
  @HiveField(19)
  @JsonKey(defaultValue: '')
  final String creatorName;

  @HiveField(20)
  @JsonKey(defaultValue: '🐻')
  final String creatorAvatar;

  /// 當前使用者是否已喜歡
  @HiveField(21)
  @JsonKey(defaultValue: false)
  final bool isLiked;

  /// 當前使用者報名狀態 (null=未報名)
  @HiveField(22)
  final GroupEventApplicationStatus? myApplicationStatus;

  GroupEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description = '',
    this.location = '',
    required this.startDate,
    this.endDate,
    this.maxMembers = 10,
    this.status = GroupEventStatus.open,
    this.approvalRequired = false,
    this.privateMessage = '',
    this.linkedTripId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.applicationCount = 0,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.creatorName = '',
    this.creatorAvatar = '🐻',
    this.isLiked = false,
    this.myApplicationStatus,
  });

  /// 是否開放報名
  bool get isOpen => status == GroupEventStatus.open;

  /// 是否已額滿
  bool get isFull => applicationCount >= maxMembers;

  /// 可報名 (開放中且未額滿)
  bool get canApply => isOpen && !isFull;

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
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxMembers,
    GroupEventStatus? status,
    bool? approvalRequired,
    String? privateMessage,
    String? linkedTripId,
    int? likeCount,
    int? commentCount,
    int? applicationCount,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    String? creatorName,
    String? creatorAvatar,
    bool? isLiked,
    GroupEventApplicationStatus? myApplicationStatus,
  }) {
    return GroupEvent(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxMembers: maxMembers ?? this.maxMembers,
      status: status ?? this.status,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      privateMessage: privateMessage ?? this.privateMessage,
      linkedTripId: linkedTripId ?? this.linkedTripId,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      applicationCount: applicationCount ?? this.applicationCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      isLiked: isLiked ?? this.isLiked,
      myApplicationStatus: myApplicationStatus ?? this.myApplicationStatus,
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
