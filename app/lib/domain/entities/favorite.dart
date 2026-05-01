import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/enums/favorite_type.dart';

part 'favorite.freezed.dart';
part 'favorite.g.dart';

/// 最愛 (Favorite) 領域實體 (Domain Entity)
@freezed
abstract class Favorite with _$Favorite {
  const Favorite._();

  const factory Favorite({
    required String id,
    required String targetId,
    required FavoriteType type,
    required DateTime createdAt,
    @Default('') String createdBy,
    DateTime? updatedAt,
    @Default('') String updatedBy,
  }) = _Favorite;

  /// 產生複合鍵 (Composite Key)
  String get compositeKey => '${type.value}_$targetId';

  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
}
