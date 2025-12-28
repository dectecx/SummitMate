import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../models/gear_library_item.dart';
import 'interfaces/i_gear_library_repository.dart';

/// 裝備庫 Repository
///
/// 管理個人裝備庫的 CRUD 操作 (本地儲存)
///
/// 【雲端備份】
/// - 透過 GearLibraryCloudService 進行
/// - 私人模式 + owner_key 識別
/// - 上傳覆寫雲端，下載覆寫本地
class GearLibraryRepository implements IGearLibraryRepository {
  static const String _boxName = HiveBoxNames.gearLibrary;

  Box<GearLibraryItem>? _box;

  /// 開啟 Box
  @override
  Future<void> init() async {
    _box = await Hive.openBox<GearLibraryItem>(_boxName);
  }

  /// 取得 Box
  Box<GearLibraryItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GearLibraryRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 取得所有裝備庫項目
  @override
  List<GearLibraryItem> getAllItems() {
    final items = box.values.toList();
    // 依名稱排序
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  /// 依 UUID 取得裝備項目
  @override
  GearLibraryItem? getById(String uuid) {
    try {
      return box.values.firstWhere((item) => item.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  /// 依類別取得裝備項目
  @override
  List<GearLibraryItem> getByCategory(String category) {
    return box.values.where((item) => item.category == category).toList();
  }

  /// 新增裝備項目
  @override
  Future<void> addItem(GearLibraryItem item) async {
    await box.put(item.uuid, item);
  }

  /// 更新裝備項目
  @override
  Future<void> updateItem(GearLibraryItem item) async {
    item.updatedAt = DateTime.now();
    await box.put(item.uuid, item);
  }

  /// 刪除裝備項目
  @override
  Future<void> deleteItem(String uuid) async {
    await box.delete(uuid);
  }

  /// 清除所有項目
  @override
  Future<void> clearAll() async {
    await box.clear();
  }

  /// 批次匯入項目 (覆寫模式)
  @override
  Future<void> importItems(List<GearLibraryItem> items) async {
    await box.clear();
    for (final item in items) {
      await box.put(item.uuid, item);
    }
  }

  /// 取得項目數量
  @override
  int get itemCount => box.length;

  /// 計算總重量 (g)
  @override
  double getTotalWeight() {
    return box.values.fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 依類別統計重量
  @override
  Map<String, double> getWeightByCategory() {
    final result = <String, double>{};
    for (final item in box.values) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }
}
