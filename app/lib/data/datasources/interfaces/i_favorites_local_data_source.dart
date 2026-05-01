import '../../../domain/enums/favorite_type.dart';
import '../../models/favorite_model.dart';

/// 最愛 (Favorites) 的本地資料來源介面
/// 管理最愛功能的本地儲存 (Hive)
abstract interface class IFavoritesLocalDataSource {
  /// 取得所有最愛項目
  Future<List<FavoriteModel>> getFavorites();

  /// 切換本地的最愛狀態 (新增或移除)
  ///
  /// [userId] 操作使用者的 ID (用於記錄 createdBy/updatedBy)
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''});

  /// 批量儲存最愛項目 (通常用於同步)
  Future<void> saveFavorites(List<FavoriteModel> rows);
}
