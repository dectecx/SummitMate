import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/meal_item.dart';

part 'meal_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MealItemModel {
  final String id;
  final String name;
  final double weight;
  final double calories;
  @JsonKey(defaultValue: 1)
  final int quantity;
  final String? note;

  MealItemModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.calories,
    this.quantity = 1,
    this.note,
  });

  MealItem toDomain() =>
      MealItem(id: id, name: name, weight: weight, calories: calories, quantity: quantity, note: note);

  factory MealItemModel.fromDomain(MealItem entity) => MealItemModel(
    id: entity.id,
    name: entity.name,
    weight: entity.weight,
    calories: entity.calories,
    quantity: entity.quantity,
    note: entity.note,
  );

  factory MealItemModel.fromJson(Map<String, dynamic> json) => _$MealItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$MealItemModelToJson(this);
}
