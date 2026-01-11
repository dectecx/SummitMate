import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/gear_item.dart';
import '../../../data/repositories/interfaces/i_gear_repository.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../core/di.dart';
import '../../cubits/gear/gear_state.dart';

/// 裝備清單 (行程) Cubit
///
/// 管理特定行程 (Trip) 中的裝備清單。
/// 功能包含：
/// - 載入行程裝備
/// - 新增/更新/刪除裝備 (透過 [IGearRepository])
/// - 勾選/取消勾選裝備 (透過 [IGearRepository])
/// - 從個人庫匯入裝備
class GearCubit extends Cubit<GearState> {
  final IGearRepository _repository;
  String? _currentTripId;

  GearCubit({IGearRepository? repository})
    : _repository = repository ?? getIt<IGearRepository>(),
      super(const GearInitial());

  String? get currentTripId => _currentTripId;

  /// 載入指定行程的裝備
  ///
  /// [tripId] 行程 ID
  Future<void> loadGear(String tripId) async {
    if (_currentTripId == tripId && state is GearLoaded) {
      return; // Already loaded for this trip
    }

    _currentTripId = tripId;
    emit(const GearLoading());

    try {
      final allItems = _repository.getAllItems();
      final tripItems = allItems.where((i) => i.tripId == tripId).toList();

      emit(GearLoaded(items: tripItems));
      LogService.debug('Loaded ${tripItems.length} gear items for trip $tripId', source: 'GearCubit');
    } catch (e) {
      LogService.error('Failed to load gear: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 重新載入當前行程的裝備
  void reload() {
    if (_currentTripId != null) {
      final allItems = _repository.getAllItems();
      final tripItems = allItems.where((i) => i.tripId == _currentTripId).toList();

      if (state is GearLoaded) {
        emit((state as GearLoaded).copyWith(items: tripItems));
      } else {
        emit(GearLoaded(items: tripItems));
      }
    }
  }

  /// 清除狀態 (登出或切換時)
  void reset() {
    _currentTripId = null;
    emit(const GearInitial());
  }

  // ========================================
  // Filter & Search Methods
  // ========================================

  void setSearchQuery(String query) {
    if (state is GearLoaded) {
      emit((state as GearLoaded).copyWith(searchQuery: query));
    }
  }

  void selectCategory(String? category) {
    if (state is GearLoaded) {
      emit((state as GearLoaded).copyWith(selectedCategory: category, clearCategory: category == null));
    }
  }

  void toggleShowUncheckedOnly() {
    if (state is GearLoaded) {
      final current = state as GearLoaded;
      emit(current.copyWith(showUncheckedOnly: !current.showUncheckedOnly));
    }
  }

  // ========================================
  // CRUD Operations
  // ========================================

  /// 新增裝備
  ///
  /// [name] 裝備名稱
  /// [weight] 重量 (g)
  /// [category] 分類
  /// [libraryItemId] 對應的預設庫 Item ID (可選)
  /// [quantity] 數量 (預設 1)
  Future<void> addItem({
    required String name,
    required double weight,
    required String category,
    String? libraryItemId,
    int quantity = 1,
  }) async {
    if (_currentTripId == null) {
      emit(const GearError('No active trip selected'));
      return;
    }

    try {
      final item = GearItem(
        name: name,
        weight: weight,
        category: category,
        isChecked: false,
        libraryItemId: libraryItemId,
        tripId: _currentTripId,
        quantity: quantity,
      );

      await _repository.addItem(item);
      reload();
    } catch (e) {
      LogService.error('Failed to add item: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 更新裝備
  ///
  /// [item] 裝備物件
  Future<void> updateItem(GearItem item) async {
    try {
      await _repository.updateItem(item);
      reload();
    } catch (e) {
      LogService.error('Failed to update item: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 更新數量
  ///
  /// [item] 目標裝備
  /// [quantity] 新數量 (至少為 1)
  Future<void> updateQuantity(GearItem item, int quantity) async {
    if (quantity < 1) quantity = 1;
    try {
      item.quantity = quantity;
      await item.save(); // Assuming HiveObject
      reload();
    } catch (e) {
      LogService.error('Failed to update quantity: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 刪除裝備
  ///
  /// [key] 裝備 Key (Hive Key)
  Future<void> deleteItem(dynamic key) async {
    try {
      await _repository.deleteItem(key);
      reload();
    } catch (e) {
      LogService.error('Failed to delete item: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 切換勾選狀態
  ///
  /// [key] 裝備 Key (Hive Key)
  Future<void> toggleChecked(dynamic key) async {
    try {
      await _repository.toggleChecked(key);
      reload();
    } catch (e) {
      LogService.error('Failed to toggle checked: $e', source: 'GearCubit');
      // For toggle, maybe don't emit error to UI, just log?
      // Or show toast via listener. For now, emit error state might disrupt navigation.
      // But let's stick to standard error handling.
      emit(GearError(e.toString()));
    }
  }

  /// 重新排序裝備
  ///
  /// [oldIndex] 原索引
  /// [newIndex] 新索引
  /// [category] 當前顯示的分類 (若有篩選)
  Future<void> reorderItem(int oldIndex, int newIndex, {String? category}) async {
    if (state is! GearLoaded) return;

    final currentState = state as GearLoaded;
    final items = currentState.items; // 該行程的所有裝備

    try {
      // 排序邏輯：
      // 1. 取得目標清單 (全部或僅限特定分類)
      final targetList = category == null ? items : items.where((item) => item.category == category).toList();

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      final List<GearItem> finalSortedList;
      if (category == null) {
        finalSortedList = targetList;
      } else {
        // 因只排序了分類子集，需合併回完整清單
        finalSortedList = List<GearItem>.from(items);
        int targetIndex = 0;
        for (int i = 0; i < finalSortedList.length; i++) {
          if (finalSortedList[i].category == category) {
            finalSortedList[i] = targetList[targetIndex++];
          }
        }
      }

      await _repository.updateItemsOrder(finalSortedList);
      reload();
    } catch (e) {
      LogService.error('Failed to reorder: $e', source: 'GearCubit');
      emit(GearError(e.toString()));
    }
  }

  /// 匯入裝備列表 (覆寫當前行程的所有裝備)
  ///
  /// [newItems] 新的裝備列表
  Future<void> replaceItems(List<GearItem> newItems) async {
    if (_currentTripId == null) return;
    try {
      emit(GearLoading());
      await _repository.clearByTripId(_currentTripId!);
      for (final item in newItems) {
        final itemToAdd = GearItem(
          tripId: _currentTripId!,
          name: item.name,
          weight: item.weight,
          category: item.category,
          quantity: item.quantity,
          isChecked: false,
          libraryItemId: item.libraryItemId,
        );
        await _repository.addItem(itemToAdd);
      }
      await loadGear(_currentTripId!);
    } catch (e) {
      LogService.error('Failed to replace items: $e', source: 'GearCubit');
      emit(GearError('匯入失敗: $e'));
      await loadGear(_currentTripId!);
    }
  }
}
