import 'package:json_annotation/json_annotation.dart';

/// 揪團報名申請狀態
enum GroupEventApplicationStatus {
  /// 待審核
  @JsonValue('pending')
  pending,

  /// 已核准 (入團)
  @JsonValue('approved')
  approved,

  /// 已拒絕
  @JsonValue('rejected')
  rejected,

  /// 已取消
  @JsonValue('cancelled')
  cancelled,
}
