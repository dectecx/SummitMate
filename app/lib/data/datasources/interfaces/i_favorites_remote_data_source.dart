import '../../../core/models/paginated_list.dart';
import '../../models/favorite.dart';
import '../../models/enums/favorite_type.dart';
import '../../../core/error/result.dart';

/// 最愛 (Favorites) 的遠端資料來源介面
abstract interface class IFavoritesRemoteDataSource {
  /// 從後端獲取最愛列表 (支援分頁)
  Future<Result<PaginatedList<Favorite>, Exception>> getFavorites({int? page, int? limit});

  /// 在後端切換最愛狀態
  ///
  /// [id] 目標物件 ID
  /// [type] 最愛類型
  /// [isFavorite] 是否設為最愛
  Future<Result<void, Exception>> updateFavorite(String id, FavoriteType type, bool isFavorite);

  /// 批量在後端更新最愛狀態
  ///
  /// [items] 包含 target_id、type、is_favorite 的清單
  Future<Result<void, Exception>> batchUpdateFavorites(List<Map<String, dynamic>> items);
}
