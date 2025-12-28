import '../../models/gear_library_item.dart';

/// 裝備庫 Repository 介面
///
/// 管理個人裝備庫的 CRUD 操作 (本地 + 雲端備份)
abstract class IGearLibraryRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得所有裝備庫項目
  List<GearLibraryItem> getAllItems();

  /// 依 UUID 取得裝備項目
  GearLibraryItem? getById(String uuid);

  /// 依類別取得裝備項目
  List<GearLibraryItem> getByCategory(String category);

  /// 新增裝備項目
  Future<void> addItem(GearLibraryItem item);

  /// 更新裝備項目
  Future<void> updateItem(GearLibraryItem item);

  /// 刪除裝備項目
  Future<void> deleteItem(String uuid);

  /// 清除所有項目
  Future<void> clearAll();

  /// 批次匯入項目 (覆寫模式)
  Future<void> importItems(List<GearLibraryItem> items);

  /// 取得項目數量
  int get itemCount;

  /// 計算總重量 (g)
  double getTotalWeight();

  /// 依類別統計重量
  Map<String, double> getWeightByCategory();
}
