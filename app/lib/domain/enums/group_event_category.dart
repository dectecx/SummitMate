import 'package:json_annotation/json_annotation.dart';

/// 揪團活動分類
@JsonEnum(valueField: 'value')
enum GroupEventCategory {
  hiking('Hiking', '登山健行'),
  camping('Camping', '露營'),
  bouldering('Bouldering', '攀岩抱石'),
  other('Other', '其他');

  /// 用於 API 與 DB 存儲的原始值
  final String value;

  /// 用於 UI 顯示的名稱
  final String displayName;

  const GroupEventCategory(this.value, this.displayName);
}
