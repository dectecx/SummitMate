import '../../models/enums/favorite_type.dart';
import '../../../core/error/result.dart';

/// 最愛 (Favorites) 的遠端資料來源介面
abstract interface class IFavoritesRemoteDataSource {
  /// 從後端獲取所有最愛列表
  Future<Result<List<Map<String, dynamic>>, Exception>> getFavorites();

  /// 在後端切換最愛狀態
  Future<Result<void, Exception>> updateFavorite(String id, FavoriteType type, bool isFavorite);
}
