import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_event_status.g.dart';

/// 揪團活動狀態
@HiveType(typeId: 14)
enum GroupEventStatus {
  /// 招募中
  @HiveField(0)
  @JsonValue('open')
  open,

  /// 已截止
  @HiveField(1)
  @JsonValue('closed')
  closed,

  /// 已取消
  @HiveField(2)
  @JsonValue('cancelled')
  cancelled,
}
