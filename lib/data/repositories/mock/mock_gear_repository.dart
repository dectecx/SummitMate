import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/gear_item.dart';
import '../interfaces/i_gear_repository.dart';
import 'mock_itinerary_repository.dart';

/// 模擬裝備資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockGearRepository implements IGearRepository {
  final List<GearItem> _mockItems = [
    GearItem(
      uuid: 'mock-gear-001',
      tripId: MockItineraryRepository.mockTripId,
      category: '睡眠系統',
      name: '睡袋',
      weight: 1200,
      quantity: 1,
      isChecked: true,
      orderIndex: 0,
    ),
    GearItem(
      uuid: 'mock-gear-002',
      tripId: MockItineraryRepository.mockTripId,
      category: '睡眠系統',
      name: '睡墊',
      weight: 500,
      quantity: 1,
      isChecked: false,
      orderIndex: 1,
    ),
    GearItem(
      uuid: 'mock-gear-003',
      tripId: MockItineraryRepository.mockTripId,
      category: '炊事系統',
      name: '爐頭',
      weight: 100,
      quantity: 1,
      isChecked: true,
      orderIndex: 2,
    ),
    GearItem(
      uuid: 'mock-gear-004',
      tripId: MockItineraryRepository.mockTripId,
      category: '穿著系統',
      name: '羽絨外套',
      weight: 400,
      quantity: 1,
      isChecked: false,
      orderIndex: 3,
    ),
  ];

  @override
  Future<void> init() async {}

  @override
  List<GearItem> getAllItems() => List.unmodifiable(_mockItems);

  @override
  List<GearItem> getItemsByCategory(String category) =>
      _mockItems.where((item) => item.category == category).toList();

  @override
  List<GearItem> getUncheckedItems() =>
      _mockItems.where((item) => !item.isChecked).toList();

  @override
  Future<int> addItem(GearItem item) async => 0;

  @override
  Future<void> updateItem(GearItem item) async {}

  @override
  Future<void> deleteItem(dynamic key) async {}

  @override
  Future<void> toggleChecked(dynamic key) async {}

  @override
  double getTotalWeight() =>
      _mockItems.fold(0, (sum, item) => sum + item.weight * item.quantity);

  @override
  double getCheckedWeight() => _mockItems
      .where((item) => item.isChecked)
      .fold(0, (sum, item) => sum + item.weight * item.quantity);

  @override
  Map<String, double> getWeightByCategory() {
    final map = <String, double>{};
    for (final item in _mockItems) {
      map[item.category] = (map[item.category] ?? 0) + item.weight * item.quantity;
    }
    return map;
  }

  @override
  Stream<BoxEvent> watchAllItems() => const Stream.empty();

  @override
  Future<void> resetAllChecked() async {}

  @override
  Future<void> updateItemsOrder(List<GearItem> items) async {}

  @override
  Future<void> clearByTripId(String tripId) async {}

  @override
  Future<void> clearAll() async {}
}
