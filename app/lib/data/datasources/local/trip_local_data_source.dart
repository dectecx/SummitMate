import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../models/trip_model.dart';
import '../../../core/constants.dart';
import '../../datasources/interfaces/i_trip_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 行程 (TripModel) 的本地資料來源實作 (使用 Hive)
@LazySingleton(as: ITripLocalDataSource)
class TripLocalDataSource implements ITripLocalDataSource {
  final Box<TripModel> box;

  TripLocalDataSource({required HiveService hiveService}) : box = hiveService.getBox<TripModel>(HiveBoxNames.trips);

  /// 取得所有行程
  @override
  List<TripModel> getAllTrips() {
    return box.values.toList();
  }

  /// 根據 ID 取得行程
  ///
  /// [id] 行程 ID
  @override
  TripModel? getTripById(String id) {
    return box.get(id);
  }

  /// 新增行程
  ///
  /// [TripModel] 欲新增的行程物件
  @override
  Future<void> addTrip(TripModel trip) async {
    await box.put(trip.id, trip);
  }

  /// 更新行程
  ///
  /// [TripModel] 更新後的行程物件
  @override
  Future<void> updateTrip(TripModel trip) async {
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
  TripModel? getActiveTrip() {
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
