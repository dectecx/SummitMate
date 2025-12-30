import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../models/gear_item.dart';
import 'interfaces/i_gear_repository.dart';

/// Gear Repository
/// 管理個人裝備的 CRUD 操作 (僅本地)
class GearRepository implements IGearRepository {
  static const String _boxName = HiveBoxNames.gear;

  Box<GearItem>? _box;

  /// 開啟 Box
  @override
  Future<void> init() async {
    _box = await Hive.openBox<GearItem>(_boxName);
  }

  /// 取得 Box
  Box<GearItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GearRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有裝備 (依 orderIndex 排序)
  @override
  List<GearItem> getAllItems() {
    final items = box.values.toList();
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
    return box.values.where((item) => item.category == category).toList();
  }

  /// 取得未打包的裝備
  @override
  List<GearItem> getUncheckedItems() {
    return box.values.where((item) => !item.isChecked).toList();
  }

  /// 新增裝備
  @override
  Future<int> addItem(GearItem item) async {
    // 自動設定 orderIndex 為目前最大值 + 1
    if (item.orderIndex == null) {
      if (box.isNotEmpty) {
        final maxOrder = box.values
            .map((i) => i.orderIndex ?? 0)
            .fold<int>(0, (max, current) => current > max ? current : max);
        item.orderIndex = maxOrder + 1;
      } else {
        item.orderIndex = 0;
      }
    }

    return await box.add(item);
  }

  /// 更新裝備
  @override
  Future<void> updateItem(GearItem item) async {
    await item.save();
  }

  /// 刪除裝備
  @override
  Future<void> deleteItem(dynamic key) async {
    await box.delete(key);
  }

  /// 切換打包狀態
  @override
  Future<void> toggleChecked(dynamic key) async {
    final item = box.get(key);
    if (item == null) return;

    item.isChecked = !item.isChecked;
    await item.save();
  }

  /// 計算總重量 (克) - 含數量乘積
  @override
  double getTotalWeight() {
    return box.values.fold<double>(0.0, (sum, item) => sum + item.totalWeight);
  }

  /// 計算已打包重量 (克) - 含數量乘積
  @override
  double getCheckedWeight() {
    return box.values.where((item) => item.isChecked).fold<double>(0.0, (sum, item) => sum + item.totalWeight);
  }

  /// 依分類統計重量
  @override
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};

    for (final item in box.values) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }

    return result;
  }

  /// 監聯裝備變更
  @override
  Stream<BoxEvent> watchAllItems() {
    return box.watch();
  }

  /// 重置所有打包狀態
  @override
  Future<void> resetAllChecked() async {
    for (final item in box.values) {
      item.isChecked = false;
      await item.save();
    }
  }

  /// 批量更新裝備順序
  @override
  Future<void> updateItemsOrder(List<GearItem> items) async {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.orderIndex != i) {
        item.orderIndex = i;
        await item.save();
      }
    }
  }

  /// 清除指定行程的所有裝備
  @override
  Future<void> clearByTripId(String tripId) async {
    final toDelete = box.values.where((item) => item.tripId == tripId).toList();
    for (final item in toDelete) {
      await item.delete();
    }
  }

  /// 清除所有裝備 (Debug 用途)
  @override
  Future<void> clearAll() async {
    await box.clear();
  }
}
