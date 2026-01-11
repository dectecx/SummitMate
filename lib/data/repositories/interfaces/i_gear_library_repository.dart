import '../../models/gear_library_item.dart';

/// 裝備庫 Repository 介面
///
/// 管理個人裝備庫的 CRUD 操作 (本地 + 雲端備份)
abstract class IGearLibraryRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得所有裝備庫項目
  ///
  /// [userId] 使用者 ID
  List<GearLibraryItem> getAllItems(String userId);

  /// 依 ID 取得裝備項目
  ///
  /// [id] 裝備 ID
  GearLibraryItem? getById(String id);

  /// 依類別取得裝備項目
  ///
  /// [userId] 使用者 ID
  /// [category] 裝備類別
  List<GearLibraryItem> getByCategory(String userId, String category);

  /// 新增裝備項目
  ///
  /// [item] 欲新增的裝備
  Future<void> addItem(GearLibraryItem item);

  /// 更新裝備項目
  ///
  /// [item] 更新後的裝備
  Future<void> updateItem(GearLibraryItem item);

  /// 刪除裝備項目
  ///
  /// [id] 裝備 ID
  Future<void> deleteItem(String id);

  /// 清除所有項目
  Future<void> clearAll();

  /// 批次匯入項目 (覆寫模式)
  ///
  /// [items] 欲匯入的裝備列表
  Future<void> importItems(List<GearLibraryItem> items);

  /// 取得項目數量
  ///
  /// [userId] 使用者 ID
  int getItemCount(String userId);

  /// 計算總重量 (g)
  ///
  /// [userId] 使用者 ID
  double getTotalWeight(String userId);

  /// 依類別統計重量
  ///
  /// [userId] 使用者 ID
  Map<String, double> getWeightByCategory(String userId);
}
