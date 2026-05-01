import '../../../core/models/paginated_list.dart';
import '../../models/gear_library_item_model.dart';
import '../../../core/error/result.dart';

/// 個人裝備庫 (Gear Library) 的遠端資料來源介面
abstract interface class IGearLibraryRemoteDataSource {
  /// 獲取個人裝備清單
  Future<Result<PaginatedList<GearLibraryItemModel>, Exception>> listLibrary({
    int? page,
    int? limit,
    String? category,
    String? search,
  });

  /// 建立個人裝備
  Future<Result<String, Exception>> create(GearLibraryItemModel item);

  /// 更新個人裝備
  Future<Result<void, Exception>> update(GearLibraryItemModel item);

  /// 刪除個人裝備
  Future<Result<void, Exception>> delete(String itemId);

  /// 替換所有個人裝備 (同步用)
  Future<Result<void, Exception>> replaceAll(List<GearLibraryItemModel> items);
}
