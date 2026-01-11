import '../../models/trip.dart';
import '../interfaces/i_trip_repository.dart';
import 'mock_itinerary_repository.dart';

/// 模擬行程清單資料庫
/// 用於教學模式，返回單一假行程，所有寫入操作皆為空實作。
class MockTripRepository implements ITripRepository {
  /// 模擬行程
  final Trip _mockTrip = Trip(
    id: MockItineraryRepository.mockTripId,
    name: '嘉明湖三天兩夜',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 2)),
    description: '向陽山 + 三叉山 + 嘉明湖',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  );

  @override
  Future<void> init() async {}

  @override
  List<Trip> getAllTrips() => [_mockTrip];

  @override
  Trip? getActiveTrip() => _mockTrip;

  @override
  Trip? getTripById(String id) => id == _mockTrip.id ? _mockTrip : null;

  @override
  Future<void> addTrip(Trip trip) async {}

  @override
  Future<void> updateTrip(Trip trip) async {}

  @override
  Future<void> deleteTrip(String id) async {}

  @override
  Future<void> setActiveTrip(String tripId) async {}

  @override
  DateTime? getLastSyncTime() => DateTime.now();

  @override
  Future<void> saveLastSyncTime(DateTime time) async {}
  @override
  Future<List<Trip>> getRemoteTrips() async => [_mockTrip];

  @override
  Future<String> uploadTripToRemote(Trip trip) async => trip.id;

  @override
  Future<void> deleteRemoteTrip(String id) async {}

  @override
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async => trip.id;

  @override
  Future<void> clearAll() async {}
}
