import '../../../domain/enums/favorite_type.dart';
import '../../../domain/entities/favorite.dart';

/// 最愛 (Favorites) 的本地資料來源介面
abstract interface class IFavoritesLocalDataSource {
  /// 取得所有最愛項目
  Future<List<Favorite>> getFavorites();

  /// 切換本地的最愛狀態 (新增或移除)
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''});

  /// 批量儲存最愛項目 (通常用於同步)
  Future<void> saveFavorites(List<Favorite> rows);
}
