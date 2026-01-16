import '../../core/error/result.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_gear_library_repository.dart';
import '../datasources/interfaces/i_gear_library_local_data_source.dart';
import '../models/gear_library_item.dart';

/// 裝備庫 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 的資料存取。
/// 雲端備份透過 GearLibraryCloudService 進行。
class GearLibraryRepository implements IGearLibraryRepository {
  static const String _source = 'GearLibraryRepository';

  final IGearLibraryLocalDataSource _localDataSource;

  GearLibraryRepository({required IGearLibraryLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      LogService.error('Init failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Data Operations ==========

  @override
  List<GearLibraryItem> getAll(String userId) {
    final items = _localDataSource.getAllItems().where((i) => i.userId == userId).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  @override
  GearLibraryItem? getById(String id) => _localDataSource.getById(id);

  @override
  List<GearLibraryItem> getByCategory(String userId, String category) {
    return getAll(userId).where((i) => i.category == category).toList();
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
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Statistics ==========

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
}
