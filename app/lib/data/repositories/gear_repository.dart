import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/i_gear_repository.dart';
import '../models/gear_item_model.dart';
import '../datasources/interfaces/i_gear_local_data_source.dart';

/// Gear Repository 實作
///
/// 位於 Data 層，負責在 Domain Entity 與 Persistence Model 之間進行轉換。
@LazySingleton(as: IGearRepository)
class GearRepository implements IGearRepository {
  final IGearLocalDataSource _localDataSource;

  GearRepository(this._localDataSource);

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  /// 取得所有裝備並轉換為 Entity (依 orderIndex 排序)
  @override
  List<GearItem> getAllItems() {
    final models = _localDataSource.getAll();

    // 排序邏輯
    models.sort((a, b) {
      if (a.orderIndex != null && b.orderIndex != null) {
        return a.orderIndex!.compareTo(b.orderIndex!);
      }
      if (a.orderIndex != null) return -1;
      if (b.orderIndex != null) return 1;
      return 0;
    });

    return models.map((m) => m.toDomain()).toList();
  }

  /// 依分類取得裝備
  @override
  List<GearItem> getItemsByCategory(String category) {
    return _localDataSource.getByCategory(category).map((m) => m.toDomain()).toList();
  }

  /// 新增裝備
  @override
  Future<Result<void, Exception>> addItem(GearItem item) async {
    try {
      final model = GearItemModel.fromDomain(item);

      // 自動設定 orderIndex
      final existingModels = _localDataSource.getAll();
      if (existingModels.isNotEmpty) {
        final maxOrder = existingModels
            .map((i) => i.orderIndex ?? 0)
            .fold<int>(0, (max, current) => current > max ? current : max);
        model.orderIndex = maxOrder + 1;
      } else {
        model.orderIndex = 0;
      }

      await _localDataSource.add(model);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 更新裝備
  @override
  Future<Result<void, Exception>> updateItem(GearItem item) async {
    try {
      final model = GearItemModel.fromDomain(item);
      await _localDataSource.update(model);
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
      final model = _localDataSource.getById(id);
      if (model != null) {
        model.isChecked = !model.isChecked;
        await _localDataSource.update(model);
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
      final models = _localDataSource.getAll();
      for (final model in models) {
        model.isChecked = false;
        await _localDataSource.update(model);
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
        final entity = items[i];
        final model = _localDataSource.getById(entity.id);
        if (model != null && model.orderIndex != i) {
          model.orderIndex = i;
          await _localDataSource.update(model);
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

  /// 從個人庫匯入預設裝備 (Stub實作，需與 GearLibraryRepository 配合)
  @override
  Future<Result<void, Exception>> importFromLibrary(String tripId, List<String> libraryItemIds) async {
    // 這裡應呼叫 Library 相關 Service 獲取資料並轉入
    return const Success(null);
  }
}
