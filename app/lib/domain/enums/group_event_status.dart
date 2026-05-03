import 'package:json_annotation/json_annotation.dart';

/// 揪團活動狀態
enum GroupEventStatus {
  /// 招募中
  @JsonValue('open')
  open,

  /// 已截止
  @JsonValue('closed')
  closed,

  /// 已取消
  @JsonValue('cancelled')
  cancelled,
}
