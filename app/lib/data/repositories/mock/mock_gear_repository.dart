import 'dart:async';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/repositories/i_gear_repository.dart';
import '../../../core/error/result.dart';
import 'mock_itinerary_repository.dart';

/// 模擬裝備資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockGearRepository implements IGearRepository {
  final List<GearItem> _mockItems = [
    GearItem(
      id: 'mock-gear-001',
      tripId: MockItineraryRepository.mockTripId,
      category: '睡眠系統',
      name: '睡袋',
      weight: 1200,
      quantity: 1,
      isChecked: true,
      orderIndex: 0,
    ),
    GearItem(
      id: 'mock-gear-002',
      tripId: MockItineraryRepository.mockTripId,
      category: '睡眠系統',
      name: '睡墊',
      weight: 500,
      quantity: 1,
      isChecked: false,
      orderIndex: 1,
    ),
    GearItem(
      id: 'mock-gear-003',
      tripId: MockItineraryRepository.mockTripId,
      category: '炊事系統',
      name: '爐頭',
      weight: 100,
      quantity: 1,
      isChecked: true,
      orderIndex: 2,
    ),
    GearItem(
      id: 'mock-gear-004',
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
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  List<GearItem> getAllItems() => List.unmodifiable(_mockItems);

  @override
  List<GearItem> getItemsByCategory(String category) => _mockItems.where((item) => item.category == category).toList();

  @override
  Future<Result<void, Exception>> addItem(GearItem item) async => const Success(null);

  @override
  Future<Result<void, Exception>> updateItem(GearItem item) async => const Success(null);

  @override
  Future<Result<void, Exception>> deleteItem(String id) async => const Success(null);

  @override
  Future<Result<void, Exception>> toggleChecked(String id) async => const Success(null);

  @override
  Future<Result<void, Exception>> resetAllChecked() async => const Success(null);

  @override
  Future<Result<void, Exception>> updateItemsOrder(List<GearItem> items) async => const Success(null);

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async => const Success(null);

  @override
  Future<Result<void, Exception>> importFromLibrary(String tripId, List<String> libraryItemIds) async =>
      const Success(null);
}
