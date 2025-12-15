import 'package:isar/isar.dart';

part 'gear_item.g.dart';

/// 個人裝備 Collection
/// 來源：僅存於本地，不與雲端同步
@collection
class GearItem {
  /// Isar Auto ID
  Id? id;

  /// 裝備名稱
  String name = '';

  /// 重量 (公克)
  double weight = 0;

  /// 裝備分類：Sleep, Cook, Wear, Other
  @Index()
  String category = '';

  /// 打包狀態
  bool isChecked = false;

  /// 建構子
  GearItem();

  /// 重量轉換為公斤
  @ignore
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearItem.fromJson(Map<String, dynamic> json) {
    return GearItem()
      ..name = json['name'] as String? ?? ''
      ..weight = (json['weight'] as num?)?.toDouble() ?? 0
      ..category = json['category'] as String? ?? 'Other'
      ..isChecked = json['is_checked'] as bool? ?? false;
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'category': category,
      'is_checked': isChecked,
    };
  }
}
