import '../../models/gear_library_item.dart';

/// 個人裝備庫 (Gear Library) 的遠端資料來源介面
abstract interface class IGearLibraryRemoteDataSource {
  /// 取得所有雲端裝備庫項目
  Future<List<GearLibraryItem>> getLibrary();

  /// 新增裝備至雲端庫
  ///
  /// [item] 欲新增的裝備項目
  Future<GearLibraryItem> addLibraryItem(GearLibraryItem item);

  /// 更新雲端裝備庫項目
  ///
  /// [item] 欲更新的裝備項目
  Future<void> updateLibraryItem(GearLibraryItem item);

  /// 從雲端庫刪除裝備
  ///
  /// [itemId] 欲刪除的裝備項目 ID
  Future<void> deleteLibraryItem(String itemId);

  /// 批量替換雲端所有裝備
  ///
  /// [items] 欲替換的裝備項目列表
  Future<void> replaceAllLibraryItems(List<GearLibraryItem> items);
}
