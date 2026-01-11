import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums/sync_status.dart';

part 'gear_library_item.g.dart';

/// 個人裝備庫項目 (Master Data)
@HiveType(typeId: 11)
@JsonSerializable(fieldRename: FieldRename.snake)
class GearLibraryItem extends HiveObject {
  /// 唯一識別碼 (PK)
  @HiveField(0)
  @JsonKey(name: 'id')
  String id;

  /// 所屬使用者 ID (Ownership)
  @HiveField(9)
  @JsonKey(name: 'user_id')
  String userId;

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

  /// 是否封存 (Soft Delete)
  @HiveField(7)
  @JsonKey(name: 'is_archived', defaultValue: false)
  bool isArchived;

  /// 同步狀態
  @HiveField(10)
  @JsonKey(name: 'sync_status', defaultValue: SyncStatus.pendingCreate)
  SyncStatus syncStatus;

  /// 建立時間
  @HiveField(5)
  @JsonKey(name: 'created_at')
  DateTime createdAt;

  /// 建立者
  @HiveField(8)
  @JsonKey(name: 'created_by')
  String createdBy;

  /// 更新時間
  @HiveField(6)
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  /// 更新者
  @HiveField(11) // New field index
  @JsonKey(name: 'updated_by')
  String updatedBy;

  GearLibraryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.weight,
    required this.category,
    this.notes,
    this.isArchived = false,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  })  : updatedAt = updatedAt ?? createdAt,
        updatedBy = updatedBy ?? createdBy;

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 從 JSON 建立
  factory GearLibraryItem.fromJson(Map<String, dynamic> json) => _$GearLibraryItemFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$GearLibraryItemToJson(this);

  @override
  String toString() => 'GearLibraryItem(id: $id, name: $name, weight: ${weight}g, category: $category, user: $userId, sync: $syncStatus)';
}
