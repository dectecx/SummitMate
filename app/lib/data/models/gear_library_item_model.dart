import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums/sync_status.dart';
import '../../domain/entities/gear_library_item.dart';

part 'gear_library_item_model.g.dart';

/// 個人裝備庫項目 (Persistence Model)
@HiveType(typeId: 11)
@JsonSerializable(fieldRename: FieldRename.snake)
class GearLibraryItemModel extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'id', required: true, disallowNullValue: true)
  String id;

  @HiveField(9)
  @JsonKey(name: 'user_id', required: true, disallowNullValue: true)
  String userId;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String name;

  @HiveField(2)
  @JsonKey(defaultValue: 0.0)
  double weight;

  @HiveField(3)
  @JsonKey(defaultValue: 'Other')
  String category;

  @HiveField(4)
  String? notes;

  @HiveField(7)
  @JsonKey(name: 'is_archived', defaultValue: false)
  bool isArchived;

  @HiveField(10)
  @JsonKey(name: 'sync_status', defaultValue: SyncStatus.pendingCreate)
  SyncStatus syncStatus;

  @HiveField(5)
  @JsonKey(name: 'created_at', fromJson: _parseDateTime, required: true, disallowNullValue: true)
  DateTime createdAt;

  @HiveField(8)
  @JsonKey(name: 'created_by', required: true, disallowNullValue: true)
  String createdBy;

  @HiveField(6)
  @JsonKey(name: 'updated_at', required: true, disallowNullValue: true)
  DateTime updatedAt;

  @HiveField(11)
  @JsonKey(name: 'updated_by', required: true, disallowNullValue: true)
  String updatedBy;

  GearLibraryItemModel({
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
    required this.updatedAt,
    required this.updatedBy,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw ArgumentError('DateTime value cannot be null');
    return DateTime.parse(value.toString()).toLocal();
  }

  /// 轉換為 Domain Entity
  GearLibraryItem toDomain() {
    return GearLibraryItem(
      id: id,
      userId: userId,
      name: name,
      weight: weight,
      category: category,
      notes: notes,
      isArchived: isArchived,
      syncStatus: syncStatus,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory GearLibraryItemModel.fromDomain(GearLibraryItem entity) {
    return GearLibraryItemModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      weight: entity.weight,
      category: entity.category,
      notes: entity.notes,
      isArchived: entity.isArchived,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory GearLibraryItemModel.fromJson(Map<String, dynamic> json) => _$GearLibraryItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$GearLibraryItemModelToJson(this);
}
