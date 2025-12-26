import 'package:hive/hive.dart';

part 'gear_item.g.dart';

/// 個人裝備
@HiveType(typeId: 3)
class GearItem extends HiveObject {
  /// 裝備名稱
  @HiveField(0)
  String name;

  /// 重量 (公克)
  @HiveField(1)
  double weight;

  /// 裝備分類：Sleep, Cook, Wear, Other
  @HiveField(2)
  String category;

  /// 打包狀態
  @HiveField(3)
  bool isChecked;

  /// 排序索引
  @HiveField(4)
  int? orderIndex;

  /// 關聯的行程 ID (null = 通用裝備)
  @HiveField(5)
  String? tripId;

  GearItem({this.name = '', this.weight = 0, this.category = '', this.isChecked = false, this.orderIndex, this.tripId});

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearItem.fromJson(Map<String, dynamic> json) {
    return GearItem(
      name: json['name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      isChecked: json['is_checked'] as bool? ?? false,
      orderIndex: json['order_index'] as int?,
      tripId: json['trip_id'] as String?,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'category': category,
      'is_checked': isChecked,
      'order_index': orderIndex,
      'trip_id': tripId,
    };
  }
}
