import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_event_application_status.g.dart';

/// 揪團報名申請狀態
@HiveType(typeId: 15)
enum GroupEventApplicationStatus {
  /// 待審核
  @HiveField(0)
  @JsonValue('pending')
  pending,

  /// 已核准 (入團)
  @HiveField(1)
  @JsonValue('approved')
  approved,

  /// 已拒絕
  @HiveField(2)
  @JsonValue('rejected')
  rejected,

  /// 已取消
  @HiveField(3)
  @JsonValue('cancelled')
  cancelled,
}
