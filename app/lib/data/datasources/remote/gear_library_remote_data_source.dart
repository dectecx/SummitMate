import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../models/gear_library_item.dart';
import '../../api/mappers/gear_library_api_mapper.dart';
import '../../api/services/gear_library_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_gear_library_remote_data_source.dart';
import '../../../core/error/result.dart';

/// 個人裝備庫 (Gear Library) 的遠端資料來源實作
@LazySingleton(as: IGearLibraryRemoteDataSource)
class GearLibraryRemoteDataSource implements IGearLibraryRemoteDataSource {
  static const String _source = 'GearLibraryRemoteDataSource';

  final GearLibraryApiService _apiService;

  GearLibraryRemoteDataSource(this._apiService);

  @override
  Future<Result<PaginatedList<GearLibraryItem>, Exception>> listLibrary({
    int? page,
    int? limit,
    String? category,
    String? search,
  }) async {
    try {
      LogService.info('獲取裝備庫列表 (page: $page, limit: $limit, search: $search)...', source: _source);
      final response = await _apiService.listItems(page: page, limit: limit, search: search);
      final items = response.items.map(GearLibraryApiMapper.fromResponse).toList();
      return Success(
        PaginatedList<GearLibraryItem>(
          items: items,
          page: response.pagination.page,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ),
      );
    } catch (e) {
      LogService.error('獲取裝備庫失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> create(GearLibraryItem item) async {
    try {
      LogService.info('建立裝備庫項目: ${item.name}', source: _source);
      final request = GearLibraryApiMapper.toRequest(item);
      final response = await _apiService.addItem(request);
      return Success(response.id);
    } catch (e) {
      LogService.error('建立裝備庫項目失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> update(GearLibraryItem item) async {
    try {
      LogService.info('更新裝備庫項目: ${item.id}', source: _source);
      final request = GearLibraryApiMapper.toRequest(item);
      await _apiService.updateItem(item.id, request);
      return const Success(null);
    } catch (e) {
      LogService.error('更新裝備庫項目失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> delete(String itemId) async {
    try {
      LogService.info('刪除裝備庫項目: $itemId', source: _source);
      await _apiService.deleteItem(itemId);
      return const Success(null);
    } catch (e) {
      LogService.error('刪除裝備庫項目失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> replaceAll(List<GearLibraryItem> items) async {
    try {
      LogService.info('替換所有裝備庫項目, 數量: ${items.length}', source: _source);
      final requests = items.map(GearLibraryApiMapper.toRequest).toList();
      await _apiService.replaceAll(requests);
      return const Success(null);
    } catch (e) {
      LogService.error('替換裝備庫項目失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
