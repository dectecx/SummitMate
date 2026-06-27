import '../../../domain/enums/favorite_type.dart';
import '../../../domain/entities/favorite.dart';

/// 最愛 (Favorites) 的本地資料來源介面（C 模式：離線可寫）
abstract interface class IFavoritesLocalDataSource {
  /// 取得可見的最愛項目（排除 pendingDelete 墓碑）
  Future<List<Favorite>> getFavorites();

  /// 取得所有本地列（含 pending／墓碑），供背景同步使用
  Future<List<Favorite>> getAllIncludingPending();

  /// 依 ID 取得單筆
  Future<Favorite?> getById(String id);

  /// 切換本地最愛狀態（離線優先：標記 pending，取消時保留墓碑）
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''});

  /// 寫入單筆（依 [Favorite.syncStatus]），供同步寫回本地
  Future<void> upsert(Favorite favorite);

  /// 硬刪除單筆
  Future<void> deleteById(String id);
}
