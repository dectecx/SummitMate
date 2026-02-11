import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../infrastructure/tools/hive_service.dart';
import 'mountain_favorites_state.dart';

/// 管理山岳收藏功能的 Cubit
/// 負責與 Hive 資料庫互動，並管理山岳收藏列表的狀態
class MountainFavoritesCubit extends Cubit<MountainFavoritesState> {
  final HiveService _hiveService;
  Box<String>? _box;

  MountainFavoritesCubit({required HiveService hiveService})
    : _hiveService = hiveService,
      super(MountainFavoritesInitial());

  /// 載入收藏列表
  Future<void> loadFavorites() async {
    try {
      emit(MountainFavoritesLoading());
      _box ??= await _hiveService.openBox<String>(HiveBoxNames.mountainFavorites);
      final ids = _box!.values.toList();
      emit(MountainFavoritesLoaded(ids));
    } catch (e) {
      emit(MountainFavoritesError("無法載入收藏: $e"));
    }
  }

  /// 切換收藏狀態 (加入/移除)
  /// [id] 為要操作的項目 ID
  Future<void> toggleFavorite(String id) async {
    if (_box == null) return;
    try {
      final currentIds = List<String>.from((state as MountainFavoritesLoaded).favoriteIds);
      if (currentIds.contains(id)) {
        // 移除邏輯 (使用 ID 作為 Key 進行刪除)
        await _box!.delete(id);
        currentIds.remove(id);
      } else {
        // 加入邏輯 (ID 同時作為 Key 和 Value)
        await _box!.put(id, id);
        currentIds.add(id);
      }
      emit(MountainFavoritesLoaded(currentIds));
    } catch (e) {
      emit(MountainFavoritesError("更新收藏失敗: $e"));
      // 發生錯誤時重新載入以確保狀態一致
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
}
