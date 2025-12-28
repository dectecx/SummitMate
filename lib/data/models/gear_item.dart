import 'package:hive/hive.dart';

part 'gear_item.g.dart';

/// 個人裝備
@HiveType(typeId: 3)
class GearItem extends HiveObject {
  /// 裝備唯一識別碼 (PK)
  @HiveField(0)
  String uuid;

  /// 關聯的行程 ID (FK → Trip，null = 通用裝備)
  @HiveField(1)
  String? tripId;

  /// 裝備名稱
  @HiveField(2)
  String name;

  /// 重量 (公克)
  @HiveField(3)
  double weight;

  /// 裝備分類：Sleep, Cook, Wear, Other
  @HiveField(4)
  String category;

  /// 打包狀態
  @HiveField(5)
  bool isChecked;

  /// 排序索引
  @HiveField(6)
  int? orderIndex;

  GearItem({
    this.uuid = '',
    this.tripId,
    this.name = '',
    this.weight = 0,
    this.category = '',
    this.isChecked = false,
    this.orderIndex,
  });

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearItem.fromJson(Map<String, dynamic> json) {
    return GearItem(
      uuid: json['uuid']?.toString() ?? '',
      tripId: json['trip_id']?.toString(),
      name: json['name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      isChecked: json['is_checked'] as bool? ?? false,
      orderIndex: json['order_index'] as int?,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'trip_id': tripId,
      'name': name,
      'weight': weight,
      'category': category,
      'is_checked': isChecked,
      'order_index': orderIndex,
    };
  }
}
