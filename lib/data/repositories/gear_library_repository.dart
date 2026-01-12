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

  GearLibraryRepository();

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

  /// 取得特定使用者的裝備列表 (過濾後的 views)
  Iterable<GearLibraryItem> _getUserItems(String userId) {
    return box.values.where((item) => item.userId == userId);
  }

  /// 取得所有裝備庫項目 (按使用者過濾)
  @override
  List<GearLibraryItem> getAllItems(String userId) {
    final items = _getUserItems(userId).toList();
    // 依名稱排序
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  /// 依 UUID 取得裝備項目
  ///
  /// [uuid] 裝備 UUID
  @override
  GearLibraryItem? getById(String id) {
    if (_box == null || !_box!.isOpen) return null;
    return box.get(id);
  }

  /// 依類別取得裝備項目
  ///
  /// [userId] 使用者 ID
  /// [category] 裝備類別
  @override
  List<GearLibraryItem> getByCategory(String userId, String category) {
    return _getUserItems(userId).where((item) => item.category == category).toList();
  }

  /// 新增裝備項目
  ///
  /// [item] 欲新增的裝備
  @override
  Future<void> addItem(GearLibraryItem item) async {
    // 自動填寫建立者 & Ownership
    // item.createdBy ??= ... (Caller handles)
    // item.userId = ... (Caller handles)

    await box.put(item.id, item);
  }

  /// 更新裝備項目
  ///
  /// [item] 更新後的裝備
  @override
  Future<void> updateItem(GearLibraryItem item) async {
    // 呼叫者負責更新 updatedAt, updatedBy, syncStatus
    await box.put(item.id, item);
  }

  /// 刪除裝備項目
  ///
  /// [uuid] 裝備 UUID
  @override
  Future<void> deleteItem(String id) async {
    await box.delete(id);
  }

  /// 清除所有項目
  @override
  Future<void> clearAll() async {
    await box.clear();
  }

  /// 批次匯入項目 (覆寫模式)
  ///
  /// [items] 欲匯入的裝備列表
  @override
  Future<void> importItems(List<GearLibraryItem> items) async {
    await box.clear();
    for (final item in items) {
      await box.put(item.id, item);
    }
  }

  /// 取得項目數量
  @override
  int getItemCount(String userId) => _getUserItems(userId).length;

  /// 計算總重量 (g)
  @override
  double getTotalWeight(String userId) {
    return _getUserItems(userId).fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  /// 依類別統計重量
  @override
  Map<String, double> getWeightByCategory(String userId) {
    final result = <String, double>{};
    for (final item in _getUserItems(userId)) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }
}
