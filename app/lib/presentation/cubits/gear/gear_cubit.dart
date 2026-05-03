import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/repositories/i_gear_repository.dart';
import '../../../core/error/app_error_handler.dart';
import '../../../core/error/result.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../cubits/gear/gear_state.dart';

/// 裝備清單 (行程) Cubit
///
/// 管理特定行程 (Trip) 中的裝備清單。
/// 功能包含：
/// - 載入行程裝備
/// - 新增/更新/刪除裝備 (透過 [IGearRepository])
/// - 勾選/取消勾選裝備 (透過 [IGearRepository])
/// - 從個人庫匯入裝備
@injectable
class GearCubit extends Cubit<GearState> {
  final IGearRepository _repository;
  String? _currentTripId;
  static const String _source = 'GearCubit';

  GearCubit(this._repository) : super(const GearInitial());

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
      final tripItems = (await _repository.getAllItems()).where((i) => i.tripId == tripId).toList();

      emit(GearLoaded(items: tripItems));
      LogService.debug('Loaded ${tripItems.length} gear items for trip $tripId', source: _source);
    } catch (e) {
      LogService.error('Failed to load gear: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 重新載入當前行程的裝備
  Future<void> reload() async {
    if (_currentTripId != null) {
      final tripItems = (await _repository.getAllItems()).where((i) => i.tripId == _currentTripId).toList();

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
        id: '', // id handled by repository or model if empty
        name: name,
        weight: weight,
        category: category,
        isChecked: false,
        libraryItemId: libraryItemId,
        tripId: _currentTripId!,
        quantity: quantity,
        createdAt: DateTime.now(),
      );

      final result = await _repository.addItem(item);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to add item: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新裝備
  Future<void> updateItem(GearItem item) async {
    try {
      final result = await _repository.updateItem(item);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to update item: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新數量
  Future<void> updateQuantity(GearItem item, int quantity) async {
    if (quantity < 1) quantity = 1;
    try {
      final updatedItem = item.copyWith(quantity: quantity);
      final result = await _repository.updateItem(updatedItem);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to update quantity: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 刪除裝備
  ///
  /// [id] 裝備 ID
  Future<void> deleteItem(String id) async {
    try {
      final result = await _repository.deleteItem(id);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to delete item: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 切換勾選狀態
  Future<void> toggleChecked(String id) async {
    try {
      final result = await _repository.toggleChecked(id);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to toggle checked: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 重新排序裝備
  Future<void> reorderItem(int oldIndex, int newIndex, {String? category}) async {
    if (state is! GearLoaded) return;

    final currentState = state as GearLoaded;
    final items = currentState.items;

    try {
      final targetList = category == null
          ? List<GearItem>.from(items)
          : items.where((item) => item.category == category).toList();

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      final List<GearItem> finalSortedList;
      if (category == null) {
        finalSortedList = targetList;
      } else {
        finalSortedList = List<GearItem>.from(items);
        int targetIndex = 0;
        for (int i = 0; i < finalSortedList.length; i++) {
          if (finalSortedList[i].category == category) {
            finalSortedList[i] = targetList[targetIndex++];
          }
        }
      }

      final result = await _repository.updateItemsOrder(finalSortedList);
      if (result is Failure) throw result.exception;
      await reload();
    } catch (e) {
      LogService.error('Failed to reorder: $e', source: _source);
      emit(GearError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 匯入裝備列表
  Future<void> replaceItems(List<GearItem> newItems) async {
    if (_currentTripId == null) return;
    try {
      emit(const GearLoading());
      await _repository.clearByTripId(_currentTripId!);

      for (final item in newItems) {
        final itemToAdd = item.copyWith(tripId: _currentTripId!, isChecked: false, createdAt: DateTime.now());
        await _repository.addItem(itemToAdd);
      }
      await loadGear(_currentTripId!);
    } catch (e) {
      LogService.error('Failed to replace items: $e', source: _source);
      emit(GearError('匯入失敗: ${AppErrorHandler.getUserMessage(e)}'));
      await loadGear(_currentTripId!);
    }
  }
}
