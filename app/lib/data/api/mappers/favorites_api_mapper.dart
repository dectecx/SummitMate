import '../../../domain/entities/favorite.dart';
import '../../../domain/enums/favorite_type.dart';
import '../models/favorites_api_models.dart';

/// Favorites API Model ↔ Domain Model 轉換
class FavoritesApiMapper {
  /// FavoriteResponse → Favorite (domain model)
  static Favorite fromResponse(FavoriteResponse response) {
    return Favorite(
      id: response.id,
      targetId: response.targetId,
      type: FavoriteType.fromValue(response.type),
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }
}
