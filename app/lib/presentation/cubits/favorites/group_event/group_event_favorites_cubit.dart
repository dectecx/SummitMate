import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/enums/favorite_type.dart';
import '../../../../data/datasources/interfaces/i_favorites_local_data_source.dart';
import 'group_event_favorites_state.dart';

/// 管理揪團收藏功能的 Cubit
/// 負責與 Drift 資料庫互動，並管理揪團收藏列表的狀態
@injectable
class GroupEventFavoritesCubit extends Cubit<GroupEventFavoritesState> {
  final IFavoritesLocalDataSource _favoritesDataSource;

  GroupEventFavoritesCubit(this._favoritesDataSource) : super(GroupEventFavoritesInitial());

  /// 載入收藏列表
  Future<void> loadFavorites() async {
    try {
      emit(GroupEventFavoritesLoading());
      final favorites = await _favoritesDataSource.getFavorites();

      // 只過濾出揪團類型的 ID
      final ids = favorites.where((f) => f.type == FavoriteType.groupEvent).map((f) => f.targetId).toList();

      emit(GroupEventFavoritesLoaded(ids));
    } catch (e) {
      emit(GroupEventFavoritesError("無法載入收藏: $e"));
    }
  }

  /// 切換收藏狀態 (加入/移除)
  /// [id] 為要操作的項目 ID
  Future<void> toggleFavorite(String id) async {
    if (state is! GroupEventFavoritesLoaded) return;

    try {
      final currentIds = List<String>.from((state as GroupEventFavoritesLoaded).favoriteIds);
      final isNowFavorite = !currentIds.contains(id);

      await _favoritesDataSource.toggleFavorite(id, FavoriteType.groupEvent, isNowFavorite);

      if (isNowFavorite) {
        currentIds.add(id);
      } else {
        currentIds.remove(id);
      }

      emit(GroupEventFavoritesLoaded(currentIds));
    } catch (e) {
      emit(GroupEventFavoritesError("更新收藏失敗: $e"));
      // 發生錯誤時重新載入以確保狀態一致
      loadFavorites();
    }
  }

  /// 檢查是否已收藏
  bool isFavorite(String id) {
    if (state is GroupEventFavoritesLoaded) {
      return (state as GroupEventFavoritesLoaded).favoriteIds.contains(id);
    }
    return false;
  }
}
