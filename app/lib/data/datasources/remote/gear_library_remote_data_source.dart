import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/gear_library_item.dart';
import '../../api/mappers/gear_library_api_mapper.dart';
import '../../api/services/gear_library_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_gear_library_remote_data_source.dart';

/// 個人裝備庫 (Gear Library) 的遠端資料來源實作
@LazySingleton(as: IGearLibraryRemoteDataSource)
class GearLibraryRemoteDataSource implements IGearLibraryRemoteDataSource {
  static const String _source = 'GearLibraryRemoteDataSource';

  final GearLibraryApiService _apiService;

  GearLibraryRemoteDataSource(this._apiService);

  @override
  Future<PaginatedList<GearLibraryItem>> getLibrary({
    bool? includeArchived,
    String? cursor,
    int? limit,
    String? search,
  }) async {
    try {
      LogService.info('取得個人裝備庫列表 (cursor: $cursor, limit: $limit, search: $search)...', source: _source);
      final response = await _apiService.listItems(
        includeArchived: includeArchived,
        cursor: cursor,
        limit: limit,
        search: search,
      );
      return PaginatedList<GearLibraryItem>(
        items: response.items.map(GearLibraryApiMapper.fromResponse).toList(),
        nextCursor: response.pagination.nextCursor,
        hasMore: response.pagination.hasMore,
      );
    } catch (e) {
      LogService.error('getLibrary 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GearLibraryItem> addLibraryItem(GearLibraryItem item) async {
    try {
      LogService.info('新增裝備至雲端庫: ${item.name}', source: _source);
      final request = GearLibraryApiMapper.toRequest(item);
      final response = await _apiService.addItem(request);
      return GearLibraryApiMapper.fromResponse(response);
    } catch (e) {
      LogService.error('addLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> updateLibraryItem(GearLibraryItem item) async {
    try {
      LogService.info('更新雲端裝備項目: ${item.id}', source: _source);
      final request = GearLibraryApiMapper.toRequest(item);
      await _apiService.updateItem(item.id, request);
    } catch (e) {
      LogService.error('updateLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteLibraryItem(String itemId) async {
    try {
      LogService.info('刪除雲端裝備項目: $itemId', source: _source);
      await _apiService.deleteItem(itemId);
    } catch (e) {
      LogService.error('deleteLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> replaceAllLibraryItems(List<GearLibraryItem> items) async {
    try {
      LogService.info('批量替換雲端裝備庫: 數量 ${items.length}', source: _source);
      await _apiService.replaceAll(items.map(GearLibraryApiMapper.toRequest).toList());
    } catch (e) {
      LogService.error('replaceAllLibraryItems 失敗: $e', source: _source);
      rethrow;
    }
  }
}
