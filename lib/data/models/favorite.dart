import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'enums/favorite_type.dart';

part 'favorite.g.dart';

/// 最愛 (Favorites) 資料模型
/// 對應資料庫/Hive 中的單筆紀錄
@HiveType(typeId: 21)
@JsonSerializable()
class Favorite {
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

  const Favorite({
    required this.id,
    required this.targetId,
    required this.type,
    required this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  /// 產生複合鍵 (Composite Key)
  /// 格式: ${type}_${targetId}
  /// 用於在單一 Box 中避免 ID 衝突
  String get compositeKey => '${type.value}_$targetId';

  Map<String, dynamic> toJson() => _$FavoriteToJson(this);

  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
}
