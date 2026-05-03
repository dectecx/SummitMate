import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/i_gear_repository.dart';
import '../datasources/interfaces/i_gear_local_data_source.dart';

/// Gear Repository 實作
///
/// 負責協調本地 Drift 資料來源，處理排序與順序自動計算邏輯。
@LazySingleton(as: IGearRepository)
class GearRepository implements IGearRepository {
  final IGearLocalDataSource _localDataSource;

  GearRepository(this._localDataSource);

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  /// 取得所有裝備 (依 orderIndex 排序)
  @override
  Future<List<GearItem>> getAllItems() async {
    final items = await _localDataSource.getAll();

    // 排序邏輯
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  /// 依分類取得裝備
  @override
  Future<List<GearItem>> getItemsByCategory(String category) async {
    return await _localDataSource.getByCategory(category);
  }

  /// 新增裝備
  @override
  Future<Result<void, Exception>> addItem(GearItem item) async {
    try {
      // 自動設定 orderIndex
      final existingItems = await _localDataSource.getAll();
      int newOrderIndex = 0;
      if (existingItems.isNotEmpty) {
        final maxOrder = existingItems
            .map((i) => i.orderIndex)
            .fold<int>(0, (max, current) => current > max ? current : max);
        newOrderIndex = maxOrder + 1;
      }

      final itemToSave = item.copyWith(orderIndex: newOrderIndex);
      await _localDataSource.add(itemToSave);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 更新裝備
  @override
  Future<Result<void, Exception>> updateItem(GearItem item) async {
    try {
      await _localDataSource.update(item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 刪除裝備 (透過 ID)
  @override
  Future<Result<void, Exception>> deleteItem(String id) async {
    try {
      await _localDataSource.deleteById(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 切換打包狀態 (透過 ID)
  @override
  Future<Result<void, Exception>> toggleChecked(String id) async {
    try {
      final item = await _localDataSource.getById(id);
      if (item != null) {
        final updatedItem = item.copyWith(isChecked: !item.isChecked);
        await _localDataSource.update(updatedItem);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 重置所有打包狀態
  @override
  Future<Result<void, Exception>> resetAllChecked() async {
    try {
      final items = await _localDataSource.getAll();
      for (final item in items) {
        if (item.isChecked) {
          await _localDataSource.update(item.copyWith(isChecked: false));
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 批量更新裝備順序
  @override
  Future<Result<void, Exception>> updateItemsOrder(List<GearItem> items) async {
    try {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.orderIndex != i) {
          await _localDataSource.update(item.copyWith(orderIndex: i));
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 清除指定行程的所有裝備
  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    try {
      await _localDataSource.clearByTripId(tripId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 從個人庫匯入預設裝備 (TODO: 與 GearLibraryRepository 配合)
  @override
  Future<Result<void, Exception>> importFromLibrary(String tripId, List<String> libraryItemIds) async {
    // TODO: 這裡應呼叫 Library 相關 Service 獲取資料並轉入
    return const Success(null);
  }
}
