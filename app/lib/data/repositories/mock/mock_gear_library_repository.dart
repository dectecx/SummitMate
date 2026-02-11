import '../../models/gear_library_item.dart';
import '../interfaces/i_gear_library_repository.dart';
import '../../../core/error/result.dart';

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
  List<GearLibraryItem> getAll(String userId) => List.unmodifiable(_mockItems);

  @override
  GearLibraryItem? getById(String id) {
    try {
      return _mockItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<GearLibraryItem> getByCategory(String userId, String category) =>
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
  int getCount(String userId) => _mockItems.length;

  @override
  double getTotalWeight(String userId) => _mockItems.fold(0, (sum, item) => sum + item.weight);

  @override
  Map<String, double> getWeightByCategory(String userId) {
    final map = <String, double>{};
    for (final item in _mockItems) {
      map[item.category] = (map[item.category] ?? 0) + item.weight;
    }
    return map;
  }
}
