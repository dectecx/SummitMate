import '../../models/enums/favorite_type.dart';
import '../../../core/error/result.dart';
import '../../models/favorite.dart';

/// 最愛 (Favorites) 的 Repository 介面
/// 管理使用者的最愛項目 (已儲存的山岳/路線)
abstract interface class IFavoritesRepository {
  /// 切換山岳或路線的最愛狀態
  ///
  /// [id] 項目 ID (例如: 山岳 ID)
  /// [type] 項目類型 (例如: FavoriteType.mountain)
  /// [isFavorite] 新的最愛狀態
  Future<Result<void, Exception>> toggleFavorite(String id, FavoriteType type, bool isFavorite);

  /// 回傳最愛項目列表 (包含 ID 與 Type)
  Future<Result<List<Favorite>, Exception>> getFavorites();
}
