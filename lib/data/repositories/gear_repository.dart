import 'package:hive/hive.dart';
import '../models/gear_item.dart';

/// Gear Repository
/// 管理個人裝備的 CRUD 操作 (僅本地)
class GearRepository {
  static const String _boxName = 'gear';

  Box<GearItem>? _box;

  /// 開啟 Box
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

  /// 取得所有裝備
  List<GearItem> getAllItems() {
    return box.values.toList();
  }

  /// 依分類取得裝備
  List<GearItem> getItemsByCategory(String category) {
    return box.values.where((item) => item.category == category).toList();
  }

  /// 取得未打包的裝備
  List<GearItem> getUncheckedItems() {
    return box.values.where((item) => !item.isChecked).toList();
  }

  /// 新增裝備
  Future<int> addItem(GearItem item) async {
    return await box.add(item);
  }

  /// 更新裝備
  Future<void> updateItem(GearItem item) async {
    await item.save();
  }

  /// 刪除裝備
  Future<void> deleteItem(dynamic key) async {
    await box.delete(key);
  }

  /// 切換打包狀態
  Future<void> toggleChecked(dynamic key) async {
    final item = box.get(key);
    if (item == null) return;

    item.isChecked = !item.isChecked;
    await item.save();
  }

  /// 計算總重量 (克)
  double getTotalWeight() {
    return box.values.fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 計算已打包重量 (克)
  double getCheckedWeight() {
    return box.values.where((item) => item.isChecked).fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 依分類統計重量
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};

    for (final item in box.values) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }

    return result;
  }

  /// 監聯裝備變更
  Stream<BoxEvent> watchAllItems() {
    return box.watch();
  }

  /// 重置所有打包狀態
  Future<void> resetAllChecked() async {
    for (final item in box.values) {
      item.isChecked = false;
      await item.save();
    }
  }

  /// 清除所有裝備 (Debug 用途)
  Future<void> clearAll() async {
    await box.clear();
  }
}
