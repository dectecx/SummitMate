import '../../models/gear_library_item.dart';
import '../../../core/error/result.dart';

/// 裝備庫資料倉庫介面 (支援 Offline-First)
///
/// 管理個人裝備庫的 CRUD 操作。
/// 裝備庫為使用者個人的裝備清單，獨立於行程儲存。
abstract class IGearLibraryRepository {
  /// 初始化本地資料庫
  ///
  /// 回傳: 初始化結果
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有裝備庫項目
  ///
  /// [userId] 使用者 ID
  /// 回傳: 裝備庫項目列表 (依名稱排序)
  List<GearLibraryItem> getAll(String userId);

  /// 依 ID 取得裝備項目
  ///
  /// [id] 裝備項目 UUID
  /// 回傳: 裝備項目，若不存在則回傳 null
  GearLibraryItem? getById(String id);

  /// 依類別取得裝備項目
  ///
  /// [userId] 使用者 ID
  /// [category] 裝備類別 (如: 睡眠系統、穿著系統)
  /// 回傳: 該類別的裝備項目列表
  List<GearLibraryItem> getByCategory(String userId, String category);

  /// 新增裝備項目
  ///
  /// [item] 欲新增的裝備項目
  Future<void> add(GearLibraryItem item);

  /// 更新裝備項目
  ///
  /// [item] 更新後的裝備項目
  Future<void> update(GearLibraryItem item);

  /// 刪除裝備項目
  ///
  /// [id] 欲刪除的裝備項目 UUID
  Future<void> delete(String id);

  /// 批次匯入項目 (覆寫模式)
  ///
  /// [items] 欲匯入的裝備項目列表
  Future<void> importAll(List<GearLibraryItem> items);

  /// 清除所有本地資料 (登出時使用)
  ///
  /// 回傳: 清除結果
  Future<Result<void, Exception>> clearAll();

  // ========== Statistics ==========

  /// 取得項目數量
  ///
  /// [userId] 使用者 ID
  /// 回傳: 該使用者的項目數量
  int getCount(String userId);

  /// 計算總重量 (克)
  ///
  /// [userId] 使用者 ID
  /// 回傳: 總重量 (g)
  double getTotalWeight(String userId);

  /// 依類別統計重量
  ///
  /// [userId] 使用者 ID
  /// 回傳: {類別名稱: 重量} 的對應表
  Map<String, double> getWeightByCategory(String userId);
}
