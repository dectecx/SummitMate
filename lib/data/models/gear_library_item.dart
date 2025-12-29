import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'gear_library_item.g.dart';

/// 個人裝備庫項目 (Master Data)
@HiveType(typeId: 11)
@JsonSerializable(fieldRename: FieldRename.snake)
class GearLibraryItem extends HiveObject {
  /// 唯一識別碼 (PK)
  @HiveField(0)
  String uuid;

  /// 裝備名稱
  @HiveField(1)
  @JsonKey(defaultValue: '')
  String name;

  /// 重量 (公克)
  @HiveField(2)
  @JsonKey(defaultValue: 0.0)
  double weight;

  /// 類別: Sleep, Cook, Wear, Other
  @HiveField(3)
  @JsonKey(defaultValue: 'Other')
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

  /// 是否封存 (Soft Delete) - 封存後不在 Autocomplete 顯示，但保留連結
  @HiveField(7)
  @JsonKey(defaultValue: false)
  bool isArchived;

  GearLibraryItem({
    String? uuid,
    required this.name,
    required this.weight,
    required this.category,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.isArchived = false,
  }) : uuid = uuid ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearLibraryItem.fromJson(Map<String, dynamic> json) => _$GearLibraryItemFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$GearLibraryItemToJson(this);

  @override
  String toString() => 'GearLibraryItem($name, ${weight}g, $category)';
}
