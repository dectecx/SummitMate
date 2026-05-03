import 'package:json_annotation/json_annotation.dart';
import 'package:hive_ce/hive.dart';
import '../../domain/enums/favorite_type.dart';
import '../../domain/entities/favorite.dart';

part 'favorite_model.g.dart';

/// 最愛 (Favorites) 持久化模型 (Persistence Model)
@HiveType(typeId: 21)
@JsonSerializable()
class FavoriteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String targetId;

  @HiveField(2)
  final FavoriteType type;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String createdBy;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final String updatedBy;

  FavoriteModel({
    required this.id,
    required this.targetId,
    required this.type,
    required this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  /// 組合鍵 (用於快取查找)
  String get compositeKey => '${type.name}_$targetId';

  /// 轉換為 Domain Entity
  Favorite toDomain() {
    return Favorite(
      id: id,
      targetId: targetId,
      type: type,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Model
  factory FavoriteModel.fromDomain(Favorite entity) {
    return FavoriteModel(
      id: entity.id,
      targetId: entity.targetId,
      type: entity.type,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  Map<String, dynamic> toJson() => _$FavoriteModelToJson(this);

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => _$FavoriteModelFromJson(json);
}
