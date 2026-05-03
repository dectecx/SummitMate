import 'dart:async';
import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/repositories/i_itinerary_repository.dart';
import '../../../core/error/result.dart';

/// 模擬行程資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockItineraryRepository implements IItineraryRepository {
  /// 模擬行程 ID（對應 MockTripRepository）
  static const String mockTripId = 'mock-trip-001';

  /// 模擬行程資料
  final List<ItineraryItem> _mockItems = [
    const ItineraryItem(
      id: 'mock-itinerary-001',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽遊樂區起登',
      estTime: '07:30',
      altitude: 2312,
      distance: 0,
      note: '檢查哨整裝出發',
    ),
    const ItineraryItem(
      id: 'mock-itinerary-002',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽山屋',
      estTime: '09:30',
      altitude: 2850,
      distance: 4.3,
      note: '',
    ),
    const ItineraryItem(
      id: 'mock-itinerary-003',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽山',
      estTime: '13:30',
      altitude: 3602,
      distance: 7.4,
      note: '百岳 No.15',
    ),
    const ItineraryItem(
      id: 'mock-itinerary-004',
      tripId: mockTripId,
      day: 'D1',
      name: '嘉明湖避難山屋',
      estTime: '15:00',
      altitude: 3380,
      distance: 8.4,
      note: '抵達山屋休息',
    ),
    const ItineraryItem(
      id: 'mock-itinerary-005',
      tripId: mockTripId,
      day: 'D2',
      name: '嘉明湖',
      estTime: '06:10',
      altitude: 3310,
      distance: 13,
      note: '天使的眼淚',
    ),
  ];

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  List<ItineraryItem> getByTripId(String tripId) => _mockItems.where((item) => item.tripId == tripId).toList();

  @override
  ItineraryItem? getById(String id) =>
      _mockItems.cast<ItineraryItem?>().firstWhere((item) => item?.id == id, orElse: () => null);

  @override
  Future<Result<void, Exception>> add(ItineraryItem item) async => const Success(null);

  @override
  Future<Result<void, Exception>> update(ItineraryItem item) async => const Success(null);

  @override
  Future<Result<void, Exception>> delete(String id) async => const Success(null);

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async => const Success(null);

  @override
  Future<Result<void, Exception>> saveAll(List<ItineraryItem> items) async => const Success(null);

  @override
  Future<Result<void, Exception>> toggleCheckIn(String id) async => const Success(null);

  @override
  Future<Result<void, Exception>> sync(String tripId) async => const Success(null);
}
