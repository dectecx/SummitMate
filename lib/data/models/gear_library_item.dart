import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'gear_library_item.g.dart';

/// 個人裝備庫項目 (Master Data)
///
/// 每個裝備的基本資訊儲存於此，可跨行程共用。
/// TripGearItem 透過 libraryItemId 連結到此，實現連動更新。
///
/// 【雲端同步】
/// - 私人模式，使用 owner_key 識別
/// - 上傳: 覆寫雲端 | 下載: 覆寫本地
///
/// 【未來規劃】
/// - 會員登入後改用 user_id 綁定
/// - 移除 owner_key 機制，自動識別帳號
@HiveType(typeId: 11)
class GearLibraryItem extends HiveObject {
  /// 唯一識別碼 (PK)
  @HiveField(0)
  String uuid;

  /// 裝備名稱
  @HiveField(1)
  String name;

  /// 重量 (公克)
  @HiveField(2)
  double weight;

  /// 類別: Sleep, Cook, Wear, Other
  @HiveField(3)
  String category;

  /// 備註
  @HiveField(4)
  String? notes;

  /// 建立時間
  @HiveField(5)
  DateTime createdAt;

  /// 更新時間
  @HiveField(6)
  DateTime? updatedAt;

  GearLibraryItem({
    String? uuid,
    required this.name,
    required this.weight,
    required this.category,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearLibraryItem.fromJson(Map<String, dynamic> json) {
    return GearLibraryItem(
      uuid: json['uuid']?.toString() ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'weight': weight,
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'GearLibraryItem($name, ${weight}g, $category)';
}
