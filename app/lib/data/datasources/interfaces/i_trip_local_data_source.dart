import '../../models/trip_model.dart';

/// 行程 (TripModel) 的本地資料來源介面
///
/// 負責定義對本地行程資料庫 (如 Hive) 的 CRUD 操作，以及管理當前活動行程。
abstract interface class ITripLocalDataSource {
  /// 初始化資料來源
  /// 取得所有行程列表
  List<TripModel> getAllTrips();

  /// 透過 ID 取得單一行程
  ///
  /// [id] 行程 ID
  TripModel? getTripById(String id);

  /// 新增行程
  ///
  /// [TripModel] 欲新增的行程物件
  Future<void> addTrip(TripModel trip);

  /// 更新行程
  ///
  /// [TripModel] 更新後的行程物件
  Future<void> updateTrip(TripModel trip);

  /// 刪除行程
  ///
  /// [id] 欲刪除的行程 ID
  Future<void> deleteTrip(String id);

  /// 設定當前活動行程 (Active TripModel)
  ///
  /// [tripId] 要設為 Active 的行程 ID
  Future<void> setActiveTrip(String tripId);

  /// 取得當前活動行程
  TripModel? getActiveTrip();

  /// 清除所有行程 (登出時使用)
  Future<void> clear();
}
