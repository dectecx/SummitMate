import '../../../domain/entities/gear_library_item.dart';

/// 裝備庫本地資料來源介面
abstract interface class IGearLibraryLocalDataSource {
  /// 取得所有裝備庫項目
  Future<List<GearLibraryItem>> getAllItems();

  /// 透過 ID 取得單一裝備項目
  Future<GearLibraryItem?> getById(String id);

  /// 儲存裝備項目
  Future<void> saveItem(GearLibraryItem item);

  /// 儲存多個裝備項目 (覆寫模式)
  Future<void> saveItems(List<GearLibraryItem> items);

  /// 刪除裝備項目
  Future<void> deleteItem(String id);

  /// 清除所有裝備庫項目
  Future<void> clear();
}
