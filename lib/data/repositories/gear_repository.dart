import 'package:isar/isar.dart';
import '../models/gear_item.dart';

/// Gear Repository
/// 管理個人裝備的 CRUD 操作 (僅本地)
class GearRepository {
  final Isar _isar;

  GearRepository(this._isar);

  /// 取得所有裝備
  Future<List<GearItem>> getAllItems() async {
    return await _isar.gearItems.where().findAll();
  }

  /// 依分類取得裝備
  Future<List<GearItem>> getItemsByCategory(String category) async {
    return await _isar.gearItems
        .filter()
        .categoryEqualTo(category)
        .findAll();
  }

  /// 取得未打包的裝備
  Future<List<GearItem>> getUncheckedItems() async {
    return await _isar.gearItems
        .filter()
        .isCheckedEqualTo(false)
        .findAll();
  }

  /// 新增裝備
  Future<int> addItem(GearItem item) async {
    return await _isar.writeTxn(() async {
      return await _isar.gearItems.put(item);
    });
  }

  /// 更新裝備
  Future<void> updateItem(GearItem item) async {
    await _isar.writeTxn(() async {
      await _isar.gearItems.put(item);
    });
  }

  /// 刪除裝備
  Future<void> deleteItem(int id) async {
    await _isar.writeTxn(() async {
      await _isar.gearItems.delete(id);
    });
  }

  /// 切換打包狀態
  Future<void> toggleChecked(int id) async {
    final item = await _isar.gearItems.get(id);
    if (item == null) return;

    item.isChecked = !item.isChecked;
    await _isar.writeTxn(() async {
      await _isar.gearItems.put(item);
    });
  }

  /// 計算總重量 (克)
  Future<double> getTotalWeight() async {
    final items = await getAllItems();
    return items.fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 計算已打包重量 (克)
  Future<double> getCheckedWeight() async {
    final items = await _isar.gearItems
        .filter()
        .isCheckedEqualTo(true)
        .findAll();
    return items.fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 依分類統計重量
  Future<Map<String, double>> getWeightByCategory() async {
    final items = await getAllItems();
    final result = <String, double>{};

    for (final item in items) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }

    return result;
  }

  /// 監聽裝備變更
  Stream<List<GearItem>> watchAllItems() {
    return _isar.gearItems.where().watch(fireImmediately: true);
  }

  /// 重置所有打包狀態
  Future<void> resetAllChecked() async {
    await _isar.writeTxn(() async {
      final items = await _isar.gearItems.where().findAll();
      for (final item in items) {
        item.isChecked = false;
      }
      await _isar.gearItems.putAll(items);
    });
  }

  /// 清除所有裝備 (Debug 用途)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.gearItems.clear();
    });
  }
}
