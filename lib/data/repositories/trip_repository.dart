import 'package:hive/hive.dart';
import '../models/trip.dart';
import 'interfaces/i_trip_repository.dart';
import '../../core/constants.dart';

/// Trip Repository 實作
/// 使用 Hive 進行本地儲存
class TripRepository implements ITripRepository {
  Box<Trip>? _box;

  @override
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Trip>(HiveBoxNames.trips);
    }
  }

  @override
  List<Trip> getAllTrips() {
    return _box?.values.toList() ?? [];
  }

  @override
  Trip? getActiveTrip() {
    final trips = getAllTrips();
    try {
      return trips.firstWhere((t) => t.isActive);
    } catch (_) {
      // 如果沒有啟用的行程，返回第一個或 null
      return trips.isNotEmpty ? trips.first : null;
    }
  }

  @override
  Trip? getTripById(String id) {
    return _box?.get(id);
  }

  @override
  Future<void> addTrip(Trip trip) async {
    await _box?.put(trip.id, trip);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await _box?.put(trip.id, trip);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _box?.delete(id);
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    final trips = getAllTrips();
    for (var trip in trips) {
      trip.isActive = (trip.id == tripId);
      await _box?.put(trip.id, trip);
    }
  }

  @override
  DateTime? getLastSyncTime() {
    // 暫時不使用，預留擴充
    return null;
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    // 暫時不使用，預留擴充
  }
}
