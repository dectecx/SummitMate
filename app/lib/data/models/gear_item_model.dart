import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/gear_item.dart';

part 'gear_item_model.g.dart';

/// 裝備項目模型 (Persistence Model)
@HiveType(typeId: 3)
@JsonSerializable(fieldRename: FieldRename.snake)
class GearItemModel extends HiveObject {
  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1)
  String? tripId;

  @HiveField(2)
  String? libraryItemId;

  @HiveField(3, defaultValue: '')
  @JsonKey(defaultValue: '')
  String name;

  @HiveField(4, defaultValue: 0.0)
  @JsonKey(defaultValue: 0.0)
  double weight;

  @HiveField(5, defaultValue: 'Other')
  @JsonKey(defaultValue: 'Other')
  String category;

  @HiveField(6, defaultValue: false)
  @JsonKey(defaultValue: false)
  bool isChecked;

  @HiveField(7)
  int? orderIndex;

  @HiveField(8, defaultValue: 1)
  @JsonKey(defaultValue: 1)
  int quantity;

  @HiveField(9)
  @JsonKey(name: 'created_at')
  DateTime? createdAt;

  @HiveField(10)
  @JsonKey(name: 'created_by')
  String? createdBy;

  @HiveField(11)
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  @HiveField(12)
  @JsonKey(name: 'updated_by')
  String? updatedBy;

  GearItemModel({
    String? id,
    this.tripId,
    this.libraryItemId,
    this.name = '',
    this.weight = 0,
    this.category = 'Other',
    this.isChecked = false,
    this.orderIndex,
    this.quantity = 1,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  }) : id = id?.isNotEmpty == true ? id! : const Uuid().v4();

  /// 轉換為 Domain Entity
  GearItem toDomain() {
    return GearItem(
      id: id,
      tripId: tripId ?? '',
      name: name,
      weight: weight,
      category: category,
      isChecked: isChecked,
      orderIndex: orderIndex ?? 0,
      quantity: quantity,
      libraryItemId: libraryItemId,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Model
  factory GearItemModel.fromDomain(GearItem entity) {
    return GearItemModel(
      id: entity.id,
      tripId: entity.tripId,
      libraryItemId: entity.libraryItemId,
      name: entity.name,
      weight: entity.weight,
      category: entity.category,
      isChecked: entity.isChecked,
      orderIndex: entity.orderIndex,
      quantity: entity.quantity,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory GearItemModel.fromJson(Map<String, dynamic> json) => _$GearItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$GearItemModelToJson(this);
}
