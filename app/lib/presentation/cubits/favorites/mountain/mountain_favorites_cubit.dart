import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import '../../../../core/core.dart';
import '../../../../domain/domain.dart';
import 'mountain_favorites_state.dart';

/// 管理山岳收藏功能的 Cubit
@injectable
class MountainFavoritesCubit extends Cubit<MountainFavoritesState> with SafeEmitMixin<MountainFavoritesState> {
  final IFavoritesRepository _favoritesRepository;

  MountainFavoritesCubit(this._favoritesRepository) : super(MountainFavoritesInitial());

  /// 載入收藏列表
  Future<void> loadFavorites() async {
    safeEmit(MountainFavoritesLoading());

    final result = await _favoritesRepository.getFavorites();

    switch (result) {
      case Success(value: final list):
        final ids = list.items
            .where((f) => f.type == FavoriteType.mountain)
            .map((f) => f.targetId)
            .toList();
        safeEmit(MountainFavoritesLoaded(ids));
      case Failure(exception: final e):
        safeEmit(MountainFavoritesError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 切換收藏狀態 (加入/移除)
  Future<void> toggleFavorite(String id) async {
    if (state is! MountainFavoritesLoaded) return;

    final currentIds = List<String>.from((state as MountainFavoritesLoaded).favoriteIds);
    final isNowFavorite = !currentIds.contains(id);

    final result = await _favoritesRepository.toggleFavorite(id, FavoriteType.mountain, isNowFavorite);

    switch (result) {
      case Success():
        if (isNowFavorite) {
          currentIds.add(id);
        } else {
          currentIds.remove(id);
        }
        safeEmit(MountainFavoritesLoaded(currentIds));
      case Failure(exception: final e):
        safeEmit(MountainFavoritesError(AppErrorHandler.getUserMessage(e)));
        loadFavorites();
    }
  }

  /// 檢查是否已收藏
  bool isFavorite(String id) {
    if (state is MountainFavoritesLoaded) {
      return (state as MountainFavoritesLoaded).favoriteIds.contains(id);
    }
    return false;
  }

  /// 重置狀態
  void reset() {
    safeEmit(MountainFavoritesInitial());
  }
}
