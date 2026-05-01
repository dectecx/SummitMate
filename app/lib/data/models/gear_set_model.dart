import 'package:json_annotation/json_annotation.dart';
import '../../domain/enums/gear_set_visibility.dart';
import '../../domain/entities/gear_set.dart';
import 'gear_item_model.dart';
import 'daily_meal_plan_model.dart';

part 'gear_set_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GearSetModel {
  final String id;
  final String title;
  final String author;
  @JsonKey(defaultValue: 0.0)
  final double totalWeight;
  @JsonKey(defaultValue: 0)
  final int itemCount;
  @JsonKey(defaultValue: GearSetVisibility.public)
  final GearSetVisibility visibility;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime uploadedAt;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;
  final String createdBy;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime updatedAt;
  final String updatedBy;
  final List<GearItemModel>? items;
  final List<DailyMealPlanModel>? meals;

  GearSetModel({
    required this.id,
    required this.title,
    required this.author,
    this.totalWeight = 0.0,
    this.itemCount = 0,
    this.visibility = GearSetVisibility.public,
    required this.uploadedAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.items,
    this.meals,
  });

  GearSet toDomain() => GearSet(
        id: id,
        title: title,
        author: author,
        totalWeight: totalWeight,
        itemCount: itemCount,
        visibility: visibility,
        uploadedAt: uploadedAt,
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        items: items?.map((i) => i.toDomain()).toList(),
        meals: meals?.map((m) => m.toDomain()).toList(),
      );

  factory GearSetModel.fromDomain(GearSet entity) => GearSetModel(
        id: entity.id,
        title: entity.title,
        author: entity.author,
        totalWeight: entity.totalWeight,
        itemCount: entity.itemCount,
        visibility: entity.visibility,
        uploadedAt: entity.uploadedAt,
        createdAt: entity.createdAt,
        createdBy: entity.createdBy,
        updatedAt: entity.updatedAt,
        updatedBy: entity.updatedBy,
        items: entity.items?.map((i) => GearItemModel.fromDomain(i)).toList(),
        meals: entity.meals?.map((m) => DailyMealPlanModel.fromDomain(m)).toList(),
      );

  factory GearSetModel.fromJson(Map<String, dynamic> json) => _$GearSetModelFromJson(json);
  Map<String, dynamic> toJson() => _$GearSetModelToJson(this);

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw ArgumentError('DateTime is required');
    if (value is DateTime) return value;
    return DateTime.parse(value.toString()).toLocal();
  }
}
