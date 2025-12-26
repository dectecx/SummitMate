import '../../models/trip.dart';

/// Trip Repository 抽象介面
/// 定義行程資料存取的契約
abstract interface class ITripRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得所有行程
  List<Trip> getAllTrips();

  /// 取得當前啟用的行程
  Trip? getActiveTrip();

  /// 根據 ID 取得行程
  Trip? getTripById(String id);

  /// 新增行程
  Future<void> addTrip(Trip trip);

  /// 更新行程
  Future<void> updateTrip(Trip trip);

  /// 刪除行程
  Future<void> deleteTrip(String id);

  /// 設定當前啟用的行程
  Future<void> setActiveTrip(String tripId);

  /// 取得上次同步時間
  DateTime? getLastSyncTime();

  /// 儲存上次同步時間
  Future<void> saveLastSyncTime(DateTime time);
}
