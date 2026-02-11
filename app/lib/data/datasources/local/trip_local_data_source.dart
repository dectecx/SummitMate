import 'package:hive/hive.dart';
import '../../models/trip.dart';
import '../../../core/constants.dart';
import '../../datasources/interfaces/i_trip_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 行程 (Trip) 的本地資料來源實作 (使用 Hive)
class TripLocalDataSource implements ITripLocalDataSource {
  final HiveService _hiveService;
  Box<Trip>? _box;

  TripLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  /// 初始化 Hive Box
  @override
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await _hiveService.openBox<Trip>(HiveBoxNames.trips);
    }
  }

  Box<Trip> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('TripLocalDataSource not initialized');
    }
    return _box!;
  }

  /// 取得所有行程
  @override
  List<Trip> getAllTrips() {
    return _box?.values.toList() ?? [];
  }

  /// 根據 ID 取得行程
  ///
  /// [id] 行程 ID
  @override
  Trip? getTripById(String id) {
    return _box?.get(id);
  }

  /// 新增行程
  ///
  /// [trip] 欲新增的行程物件
  @override
  Future<void> addTrip(Trip trip) async {
    await box.put(trip.id, trip);
  }

  /// 更新行程
  ///
  /// [trip] 更新後的行程物件
  @override
  Future<void> updateTrip(Trip trip) async {
    await box.put(trip.id, trip);
  }

  /// 刪除行程
  ///
  /// [id] 欲刪除的行程 ID
  @override
  Future<void> deleteTrip(String id) async {
    await box.delete(id);
  }

  /// 取得當前活動行程
  @override
  Trip? getActiveTrip() {
    final trips = getAllTrips();
    try {
      return trips.firstWhere((t) => t.isActive);
    } catch (_) {
      return trips.isNotEmpty ? trips.first : null;
    }
  }

  /// 設定當前活動行程
  ///
  /// 將指定 [tripId] 的行程設為 active，其餘設為 inactive
  @override
  Future<void> setActiveTrip(String tripId) async {
    final trips = getAllTrips();
    for (var trip in trips) {
      bool isActive = (trip.id == tripId);
      if (trip.isActive != isActive) {
        trip.isActive = isActive;
        await box.put(trip.id, trip);
      }
    }
  }

  /// 清除所有行程
  @override
  Future<void> clear() async {
    await box.clear();
  }
}
