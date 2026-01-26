import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../infrastructure/tools/hive_service.dart';
import 'group_event_favorites_state.dart';

/// 管理揪團收藏功能的 Cubit
/// 負責與 Hive 資料庫互動，並管理揪團收藏列表的狀態
class GroupEventFavoritesCubit extends Cubit<GroupEventFavoritesState> {
  final HiveService _hiveService;
  Box<String>? _box;

  GroupEventFavoritesCubit({required HiveService hiveService})
    : _hiveService = hiveService,
      super(GroupEventFavoritesInitial());

  /// 載入收藏列表
  Future<void> loadFavorites() async {
    try {
      emit(GroupEventFavoritesLoading());
      _box ??= await _hiveService.openBox<String>(HiveBoxNames.groupEventFavorites);
      final ids = _box!.values.toList();
      emit(GroupEventFavoritesLoaded(ids));
    } catch (e) {
      emit(GroupEventFavoritesError("無法載入收藏: $e"));
    }
  }

  /// 切換收藏狀態 (加入/移除)
  /// [id] 為要操作的項目 ID
  Future<void> toggleFavorite(String id) async {
    if (_box == null) return;
    try {
      final currentIds = List<String>.from((state as GroupEventFavoritesLoaded).favoriteIds);
      if (currentIds.contains(id)) {
        // 移除邏輯
        await _box!.delete(id);
        currentIds.remove(id);
      } else {
        // 加入邏輯
        await _box!.put(id, id);
        currentIds.add(id);
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
