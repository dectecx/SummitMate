import 'package:summitmate/domain/domain.dart';
import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';

/// 模擬裝備庫資料倉庫
///
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockGearLibraryRepository implements IGearLibraryRepository {
  final List<GearLibraryItem> _mockItems = [
    GearLibraryItem(
      id: 'mock-lib-001',
      userId: 'guest',
      category: '睡眠系統',
      name: '輕量睡袋',
      weight: 800,
      notes: '適用 0~10°C',
      createdAt: DateTime.now(),
      createdBy: 'guest',
      updatedAt: DateTime.now(),
      updatedBy: 'guest',
    ),
    GearLibraryItem(
      id: 'mock-lib-002',
      userId: 'guest',
      category: '穿著系統',
      name: '風雨衣',
      weight: 300,
      notes: 'Gore-Tex',
      createdAt: DateTime.now(),
      createdBy: 'guest',
      updatedAt: DateTime.now(),
      updatedBy: 'guest',
    ),
  ];

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  // ========== Data Operations ==========

  @override
  Future<List<GearLibraryItem>> getAll(String userId) async => List.unmodifiable(_mockItems);

  @override
  Future<GearLibraryItem?> getById(String id) async {
    try {
      return _mockItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<GearLibraryItem>> getByCategory(String userId, String category) async =>
      _mockItems.where((item) => item.category == category).toList();

  @override
  Future<void> add(GearLibraryItem item) async {}

  @override
  Future<void> update(GearLibraryItem item) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> importAll(List<GearLibraryItem> items) async {}

  @override
  Future<Result<void, Exception>> clearAll() async => const Success(null);

  // ========== Statistics ==========

  @override
  Future<int> getCount(String userId) async => _mockItems.length;

  @override
  Future<double> getTotalWeight(String userId) async => _mockItems.fold<double>(0, (sum, item) => sum + item.weight);

  @override
  Future<Map<String, double>> getWeightByCategory(String userId) async {
    final map = <String, double>{};
    for (final item in _mockItems) {
      map[item.category] = (map[item.category] ?? 0) + item.weight;
    }
    return map;
  }

  @override
  Future<Result<PaginatedList<GearLibraryItem>, Exception>> getRemoteItems({
    int? page,
    int? limit,
    String? category,
    String? search,
  }) async {
    return Success(PaginatedList(items: [], page: page ?? 1, total: 0, hasMore: false));
  }

  @override
  Future<Result<void, Exception>> syncRemoteItems(List<GearLibraryItem> items) async {
    return const Success(null);
  }
}
