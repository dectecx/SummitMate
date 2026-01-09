import '../../core/di.dart';
import '../models/gear_item.dart';
import 'interfaces/i_gear_repository.dart';
import '../datasources/interfaces/i_gear_local_data_source.dart';
import 'package:hive/hive.dart';

/// Gear Repository
/// 管理個人裝備的 CRUD 操作 (僅本地)
/// Delegates to GearLocalDataSource
class GearRepository implements IGearRepository {
  final IGearLocalDataSource _localDataSource;

  GearRepository({IGearLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? getIt<IGearLocalDataSource>();

  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  /// 取得所有裝備 (依 orderIndex 排序)
  @override
  List<GearItem> getAllItems() {
    final items = _localDataSource.getAll();
    items.sort((a, b) {
      if (a.orderIndex != null && b.orderIndex != null) {
        return a.orderIndex!.compareTo(b.orderIndex!);
      }
      // 如果沒有 orderIndex，將其視為無限大 (排在最後)
      if (a.orderIndex != null) return -1;
      if (b.orderIndex != null) return 1;
      return 0;
    });
    return items;
  }

  /// 依分類取得裝備
  @override
  List<GearItem> getItemsByCategory(String category) {
    return _localDataSource.getByCategory(category);
  }

  /// 取得未打包的裝備
  @override
  List<GearItem> getUncheckedItems() {
    return _localDataSource.getUnchecked();
  }

  /// 新增裝備
  @override
  Future<int> addItem(GearItem item) async {
    // 自動設定 orderIndex 為目前最大值 + 1
    if (item.orderIndex == null) {
      final items = _localDataSource.getAll();
      if (items.isNotEmpty) {
        final maxOrder = items
            .map((i) => i.orderIndex ?? 0)
            .fold<int>(0, (max, current) => current > max ? current : max);
        item.orderIndex = maxOrder + 1;
      } else {
        item.orderIndex = 0;
      }
    }

    return await _localDataSource.add(item);
  }

  /// 更新裝備
  @override
  Future<void> updateItem(GearItem item) async {
    await _localDataSource.update(item);
  }

  /// 刪除裝備
  @override
  Future<void> deleteItem(dynamic key) async {
    await _localDataSource.delete(key);
  }

  /// 切換打包狀態
  @override
  Future<void> toggleChecked(dynamic key) async {
    // 透過 LocalDataSource 直接取得 Item (Hive Key)
    final item = _localDataSource.getByKey(key);
    if (item != null) {
      item.isChecked = !item.isChecked;
      await _localDataSource.update(item);
    }
  }

  /// 計算總重量 (克) - 含數量乘積
  @override
  double getTotalWeight() {
    return _localDataSource.getAll().fold<double>(0.0, (sum, item) => sum + item.totalWeight);
  }

  /// 計算已打包重量 (克) - 含數量乘積
  @override
  double getCheckedWeight() {
    return _localDataSource
        .getAll()
        .where((item) => item.isChecked)
        .fold<double>(0.0, (sum, item) => sum + item.totalWeight);
  }

  /// 依分類統計重量
  @override
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};
    for (final item in _localDataSource.getAll()) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }

  /// 監聯裝備變更
  @override
  Stream<BoxEvent> watchAllItems() {
    return _localDataSource.watch();
  }

  /// 重置所有打包狀態
  @override
  Future<void> resetAllChecked() async {
    for (final item in _localDataSource.getAll()) {
      item.isChecked = false;
      await _localDataSource.update(item);
    }
  }

  /// 批量更新裝備順序
  @override
  Future<void> updateItemsOrder(List<GearItem> items) async {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.orderIndex != i) {
        item.orderIndex = i;
        await _localDataSource.update(item);
      }
    }
  }

  /// 清除指定行程的所有裝備
  @override
  Future<void> clearByTripId(String tripId) async {
    await _localDataSource.clearByTripId(tripId);
  }

  /// 清除所有裝備 (Debug 用途)
  @override
  Future<void> clearAll() async {
    await _localDataSource.clearAll();
  }
}
