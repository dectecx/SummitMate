import '../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../entities/gear_library_item.dart';

/// 裝備庫資料倉庫介面（支援 Offline-First）
///
/// 管理個人裝備庫的 CRUD 操作。
/// 裝備庫為使用者個人的裝備清單，獨立於行程儲存。
abstract class IGearLibraryRepository {
  /// 初始化本地資料庫
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得所有裝備庫項目（本地，依名稱排序）
  Future<List<GearLibraryItem>> getAll(String userId);

  /// 取得雲端裝備庫項目（分頁）
  Future<Result<PaginatedList<GearLibraryItem>, Exception>> getRemoteItems({int? page, int? limit, String? search});

  /// 依 ID 取得裝備項目
  Future<GearLibraryItem?> getById(String id);

  /// 依類別取得裝備項目
  Future<List<GearLibraryItem>> getByCategory(String userId, String category);

  /// 新增裝備項目
  Future<void> add(GearLibraryItem item);

  /// 更新裝備項目
  Future<void> update(GearLibraryItem item);

  /// 刪除裝備項目
  Future<void> delete(String id);

  /// 批次匯入項目（覆寫模式）
  Future<void> importAll(List<GearLibraryItem> items);

  /// 清除所有本地資料（登出時使用）
  Future<Result<void, Exception>> clearAll();

  // ========== Statistics ==========

  /// 取得項目數量
  Future<int> getCount(String userId);

  /// 計算總重量（克）
  Future<double> getTotalWeight(String userId);

  /// 依類別統計重量
  Future<Map<String, double>> getWeightByCategory(String userId);

  /// 同步至雲端 (完全替換)
  Future<Result<void, Exception>> syncRemoteItems(List<GearLibraryItem> items);
}
