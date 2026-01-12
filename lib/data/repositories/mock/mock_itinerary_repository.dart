import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/itinerary_item.dart';
import '../interfaces/i_itinerary_repository.dart';

/// 模擬行程資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockItineraryRepository implements IItineraryRepository {
  /// 模擬行程 ID（對應 MockTripRepository）
  static const String mockTripId = 'mock-trip-001';

  DateTime? _lastSyncTime;

  /// 模擬行程資料
  final List<ItineraryItem> _mockItems = [
    ItineraryItem(
      id: 'mock-itinerary-001',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽遊樂區起登',
      estTime: '07:30',
      altitude: 2312,
      distance: 0,
      note: '檢查哨整裝出發',
    ),
    ItineraryItem(
      id: 'mock-itinerary-002',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽山屋',
      estTime: '09:30',
      altitude: 2850,
      distance: 4.3,
      note: '',
    ),
    ItineraryItem(
      id: 'mock-itinerary-003',
      tripId: mockTripId,
      day: 'D1',
      name: '向陽山',
      estTime: '13:30',
      altitude: 3602,
      distance: 7.4,
      note: '百岳 No.15',
    ),
    ItineraryItem(
      id: 'mock-itinerary-004',
      tripId: mockTripId,
      day: 'D1',
      name: '嘉明湖避難山屋',
      estTime: '15:00',
      altitude: 3380,
      distance: 8.4,
      note: '抵達山屋休息',
    ),
    ItineraryItem(
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
  Future<void> init() async {}

  @override
  List<ItineraryItem> getAllItems() => List.unmodifiable(_mockItems);

  @override
  List<ItineraryItem> getItemsByDay(String day) => _mockItems.where((item) => item.day == day).toList();

  @override
  ItineraryItem? getItemByKey(dynamic key) =>
      _mockItems.cast<ItineraryItem?>().firstWhere((item) => item?.id == key, orElse: () => null);

  @override
  Future<void> checkIn(dynamic key, DateTime time) async {}

  @override
  Future<void> clearCheckIn(dynamic key) async {}

  @override
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems) async {}

  @override
  Stream<BoxEvent> watchAllItems() => const Stream.empty();

  @override
  Future<void> resetAllCheckIns() async {}

  @override
  Future<void> addItem(ItineraryItem item) async {}

  @override
  Future<void> updateItem(dynamic key, ItineraryItem item) async {}

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    _lastSyncTime = time;
  }

  @override
  DateTime? getLastSyncTime() {
    return _lastSyncTime;
  }

  @override
  Future<void> sync(String tripId) async {
    // Mock sync
  }

  @override
  Future<void> deleteItem(dynamic key) async {}

  @override
  Future<void> clearAll() async {}
}
