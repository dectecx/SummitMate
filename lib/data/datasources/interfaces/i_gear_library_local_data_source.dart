import '../../models/gear_library_item.dart';

/// 裝備庫本地資料來源介面
///
/// 負責定義對本地資料庫 (Hive) 的 CRUD 操作。
/// 裝備庫為使用者個人的裝備清單，獨立於行程儲存。
abstract class IGearLibraryLocalDataSource {
  /// 初始化資料來源
  ///
  /// 開啟 Hive Box，需在使用其他方法前呼叫。
  Future<void> init();

  /// 取得所有裝備庫項目
  ///
  /// 回傳: 裝備庫項目列表
  List<GearLibraryItem> getAllItems();

  /// 透過 ID 取得單一裝備項目
  ///
  /// [id] 裝備項目 UUID
  /// 回傳: 裝備項目，若不存在則回傳 null
  GearLibraryItem? getById(String id);

  /// 儲存裝備項目
  ///
  /// [item] 欲儲存的裝備項目 (新增或更新)
  Future<void> saveItem(GearLibraryItem item);

  /// 儲存多個裝備項目 (覆寫模式)
  ///
  /// [items] 欲儲存的裝備項目列表，會清除現有資料後寫入
  Future<void> saveItems(List<GearLibraryItem> items);

  /// 刪除裝備項目
  ///
  /// [id] 欲刪除的裝備項目 UUID
  Future<void> deleteItem(String id);

  /// 清除所有裝備庫項目
  ///
  /// 用於登出或重置情境。
  Future<void> clear();
}
