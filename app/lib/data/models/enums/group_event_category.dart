import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_event_category.g.dart';

/// 揪團活動分類
@HiveType(typeId: 14)
@JsonEnum(valueField: 'value')
enum GroupEventCategory {
  @HiveField(0)
  hiking('Hiking', '登山健行'),

  @HiveField(1)
  camping('Camping', '露營'),

  @HiveField(2)
  bouldering('Bouldering', '攀岩抱石'),

  @HiveField(3)
  other('Other', '其他');

  /// 用於 API 與 DB 存儲的原始值
  final String value;

  /// 用於 UI 顯示的名稱
  final String displayName;

  const GroupEventCategory(this.value, this.displayName);
}
