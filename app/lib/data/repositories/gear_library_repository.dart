import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../../infrastructure/tools/log_service.dart';
import '../datasources/interfaces/i_gear_library_local_data_source.dart';
import '../datasources/interfaces/i_gear_library_remote_data_source.dart';
import '../models/gear_library_item_model.dart';
import 'package:summitmate/domain/domain.dart';

/// 裝備庫 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 的資料存取。
/// 雲端備份透過 GearLibraryCloudService 進行。
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
  List<GearLibraryItem> getAll(String userId) {
    final models = _localDataSource.getAllItems().where((i) => i.userId == userId).toList();
    models.sort((a, b) => a.name.compareTo(b.name));
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  GearLibraryItem? getById(String id) => _localDataSource.getById(id)?.toDomain();

  @override
  List<GearLibraryItem> getByCategory(String userId, String category) {
    return getAll(userId).where((i) => i.category == category).toList();
  }

  @override
  Future<void> add(GearLibraryItem item) => _localDataSource.saveItem(GearLibraryItemModel.fromDomain(item));

  @override
  Future<void> update(GearLibraryItem item) => _localDataSource.saveItem(GearLibraryItemModel.fromDomain(item));

  @override
  Future<void> delete(String id) => _localDataSource.deleteItem(id);

  @override
  Future<void> importAll(List<GearLibraryItem> items) => 
      _localDataSource.saveItems(items.map((i) => GearLibraryItemModel.fromDomain(i)).toList());

  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all gear library items (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  int getCount(String userId) => getAll(userId).length;

  @override
  double getTotalWeight(String userId) {
    return getAll(userId).fold<double>(0.0, (sum, item) => sum + item.weight);
  }

  @override
  Map<String, double> getWeightByCategory(String userId) {
    final result = <String, double>{};
    for (final item in getAll(userId)) {
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
      for (final item in result.value.items) {
        await _localDataSource.saveItem(GearLibraryItemModel.fromDomain(item));
      }
      return result;
    }
    return Failure((result as Failure).exception);
  }

  @override
  Future<Result<void, Exception>> syncRemoteItems(List<GearLibraryItem> items) async {
    return _remoteDataSource.replaceAll(items);
  }
}
