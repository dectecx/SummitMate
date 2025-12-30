import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'gear_item.g.dart';

/// 行程裝備項目
///
/// 【連結模式】libraryItemId 有值
/// - name/weight/category 從 GearLibrary 即時讀取
/// - 修改 GearLibrary 會自動反映到此項目
///
/// 【獨立模式】libraryItemId 為空
/// - 使用自身 name/weight/category
/// - 適用於下載他人組合但不加入庫的情況
@HiveType(typeId: 3)
@JsonSerializable(fieldRename: FieldRename.snake)
class GearItem extends HiveObject {
  // ========================================
  // PK (Primary Key)
  // ========================================

  /// 裝備唯一識別碼 (PK)
  @HiveField(0)
  String uuid;

  // ========================================
  // FK (Foreign Keys)
  // ========================================

  /// 關聯的行程 ID (FK → Trip)
  @HiveField(1)
  String? tripId;

  /// 關聯的裝備庫項目 ID (FK → GearLibraryItem)
  /// null = 獨立模式，不從裝備庫連動
  @HiveField(2)
  String? libraryItemId;

  // ========================================
  // Data Fields
  // ========================================

  /// 裝備名稱 (獨立模式用，連結模式為快取)
  @HiveField(3)
  @JsonKey(defaultValue: '')
  String name;

  /// 重量 (公克，獨立模式用，連結模式為快取)
  @HiveField(4)
  @JsonKey(defaultValue: 0.0)
  double weight;

  /// 裝備分類：Sleep, Cook, Wear, Other
  @HiveField(5)
  @JsonKey(defaultValue: 'Other')
  String category;

  /// 打包狀態
  @HiveField(6)
  @JsonKey(defaultValue: false)
  bool isChecked;

  /// 排序索引
  @HiveField(7)
  int? orderIndex;

  // ========================================
  // Constructor
  // ========================================

  GearItem({
    String? uuid,
    this.tripId,
    this.libraryItemId,
    this.name = '',
    this.weight = 0,
    this.category = 'Other',
    this.isChecked = false,
    this.orderIndex,
    this.quantity = 1,
  }) : uuid = uuid?.isNotEmpty == true ? uuid! : const Uuid().v4();

  // ========================================
  // Computed Properties
  // ========================================

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 數量 (預設 1)
  @HiveField(8)
  @JsonKey(defaultValue: 1)
  int quantity;

  /// 總重量 (重量 × 數量)
  double get totalWeight => weight * quantity;

  /// 是否連結到裝備庫
  bool get isLinkedToLibrary => libraryItemId != null;

  // ========================================
  // Serialization
  // ========================================

  /// 從 JSON 建立
  factory GearItem.fromJson(Map<String, dynamic> json) => _$GearItemFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$GearItemToJson(this);
}
