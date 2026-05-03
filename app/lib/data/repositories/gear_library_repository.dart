import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../../infrastructure/tools/log_service.dart';
import '../datasources/interfaces/i_gear_library_local_data_source.dart';
import '../datasources/interfaces/i_gear_library_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';

/// 裝備庫 Repository 實作
@LazySingleton(as: IGearLibraryRepository)
class GearLibraryRepository implements IGearLibraryRepository {
  static const String _source = 'GearLibraryRepository';

  final IGearLibraryLocalDataSource _localDataSource;
  final IGearLibraryRemoteDataSource _remoteDataSource;

  GearLibraryRepository({
    required IGearLibraryLocalDataSource localDataSource,
    required IGearLibraryRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  Future<List<GearLibraryItem>> getAll(String userId) async {
    final items = await _localDataSource.getAllItems();
    final userItems = items.where((i) => i.userId == userId).toList();
    userItems.sort((a, b) => a.name.compareTo(b.name));
    return userItems;
  }

  @override
  Future<GearLibraryItem?> getById(String id) => _localDataSource.getById(id);

  @override
  Future<List<GearLibraryItem>> getByCategory(String userId, String category) async {
    final items = await getAll(userId);
    return items.where((i) => i.category == category).toList();
  }

  @override
  Future<void> add(GearLibraryItem item) => _localDataSource.saveItem(item);

  @override
  Future<void> update(GearLibraryItem item) => _localDataSource.saveItem(item);

  @override
  Future<void> delete(String id) => _localDataSource.deleteItem(id);

  @override
  Future<void> importAll(List<GearLibraryItem> items) => _localDataSource.saveItems(items);

  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all gear library items (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<int> getCount(String userId) async {
    final items = await getAll(userId);
    return items.length;
  }

  @override
  Future<double> getTotalWeight(String userId) async {
    final items = await getAll(userId);
    return items.fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  @override
  Future<Map<String, double>> getWeightByCategory(String userId) async {
    final items = await getAll(userId);
    final result = <String, double>{};
    for (final item in items) {
      result[item.category] = (result[item.category] ?? 0) + item.weight;
    }
    return result;
  }

  @override
  Future<Result<PaginatedList<GearLibraryItem>, Exception>> getRemoteItems({
    int? page,
    int? limit,
    String? category,
    String? search,
  }) async {
    final result = await _remoteDataSource.listLibrary(page: page, limit: limit, category: category, search: search);
    if (result is Success<PaginatedList<GearLibraryItem>, Exception>) {
      await _localDataSource.saveItems(result.value.items);
      return result;
    }
    return Failure((result as Failure).exception);
  }

  @override
  Future<Result<void, Exception>> syncRemoteItems(List<GearLibraryItem> items) async {
    return _remoteDataSource.replaceAll(items);
  }
}
