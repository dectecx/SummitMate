import '../../domain/entities/gear_item.dart';
import '../../../core/error/result.dart';

/// 裝備 Repository 抽象介面
///
/// 位於 Domain 層，定義裝備資料存取的契約。
abstract interface class IGearRepository {
  /// 初始化
  Future<Result<void, Exception>> init();

  // ========== Data Operations ==========

  /// 取得行程的所有裝備
  Future<List<GearItem>> getAllItems();

  /// 依分類取得裝備
  Future<List<GearItem>> getItemsByCategory(String category);

  /// 新增裝備
  Future<Result<void, Exception>> addItem(GearItem item);

  /// 更新裝備
  Future<Result<void, Exception>> updateItem(GearItem item);

  /// 刪除裝備
  Future<Result<void, Exception>> deleteItem(String id);

  /// 批量更新裝備順序
  Future<Result<void, Exception>> updateItemsOrder(List<GearItem> items);

  /// 清除行程所有裝備
  Future<Result<void, Exception>> clearByTripId(String tripId);

  // ========== Check Operations ==========

  /// 切換打包狀態
  Future<Result<void, Exception>> toggleChecked(String id);

  /// 重置所有打包狀態
  Future<Result<void, Exception>> resetAllChecked();

  // ========== Library Operations ==========

  /// 從個人庫匯入預設裝備
  Future<Result<void, Exception>> importFromLibrary(String tripId, List<String> libraryItemIds);
}
