import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import '../../../../core/core.dart';
import '../../../../domain/domain.dart';
import 'group_event_favorites_state.dart';

/// 管理揪團收藏功能的 Cubit
@injectable
class GroupEventFavoritesCubit extends Cubit<GroupEventFavoritesState> with SafeEmitMixin<GroupEventFavoritesState> {
  final IFavoritesRepository _favoritesRepository;

  GroupEventFavoritesCubit(this._favoritesRepository) : super(GroupEventFavoritesInitial());

  /// 載入收藏列表
  Future<void> loadFavorites() async {
    safeEmit(GroupEventFavoritesLoading());

    final result = await _favoritesRepository.getFavorites();

    switch (result) {
      case Success(value: final list):
        final ids = list.items
            .where((f) => f.type == FavoriteType.groupEvent)
            .map((f) => f.targetId)
            .toList();
        safeEmit(GroupEventFavoritesLoaded(ids));
      case Failure(exception: final e):
        safeEmit(GroupEventFavoritesError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 切換收藏狀態 (加入/移除)
  Future<void> toggleFavorite(String id) async {
    if (state is! GroupEventFavoritesLoaded) return;

    final currentIds = List<String>.from((state as GroupEventFavoritesLoaded).favoriteIds);
    final isNowFavorite = !currentIds.contains(id);

    final result = await _favoritesRepository.toggleFavorite(id, FavoriteType.groupEvent, isNowFavorite);

    switch (result) {
      case Success():
        if (isNowFavorite) {
          currentIds.add(id);
        } else {
          currentIds.remove(id);
        }
        safeEmit(GroupEventFavoritesLoaded(currentIds));
      case Failure(exception: final e):
        safeEmit(GroupEventFavoritesError(AppErrorHandler.getUserMessage(e)));
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

  /// 重置狀態
  void reset() {
    safeEmit(GroupEventFavoritesInitial());
  }
}
