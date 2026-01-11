import '../../models/trip.dart';

/// Trip Repository 抽象介面
/// 定義行程資料存取的契約
abstract interface class ITripRepository {
  /// 初始化 Repository
  Future<void> init();

  /// 取得所有行程
  ///
  /// [userId] 使用者 ID
  List<Trip> getAllTrips(String userId);

  /// 取得當前啟用的行程
  ///
  /// [userId] 使用者 ID
  Trip? getActiveTrip(String userId);

  /// 透過 ID 取得單一行程
  ///
  /// [id] 行程 ID
  Trip? getTripById(String id);

  /// 新增行程 (本地)
  ///
  /// [trip] 欲新增的行程物件
  Future<void> addTrip(Trip trip);

  /// 更新行程
  ///
  /// [trip] 更新後的行程物件
  Future<void> updateTrip(Trip trip);

  /// 刪除行程
  ///
  /// [id] 欲刪除的行程 ID
  Future<void> deleteTrip(String id);

  /// 設定當前啟用的行程 (Active Trip)
  ///
  /// [tripId] 要設為 Active 的行程 ID
  Future<void> setActiveTrip(String tripId);

  /// 取得上次同步時間
  DateTime? getLastSyncTime();

  /// 儲存上次同步時間
  ///
  /// [time] 同步時間
  Future<void> saveLastSyncTime(DateTime time);

  /// 取得遠端行程列表 (Cloud Management)
  Future<List<Trip>> getRemoteTrips();

  /// 上傳行程至遠端 (手動備份用)
  ///
  /// [trip] 欲上傳的行程
  /// 回傳: 上傳結果訊息
  Future<String> uploadTripToRemote(Trip trip);

  /// 刪除遠端行程
  ///
  /// [id] 欲刪除的遠端行程 ID
  Future<void> deleteRemoteTrip(String id);

  /// 完整上傳行程 (包含行程表與裝備)
  ///
  /// [trip] 行程物件
  /// [itineraryItems] 行程節點列表
  /// [gearItems] 裝備列表
  /// 回傳: 上傳結果訊息
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  });

  /// 清除所有本地行程資料 (登出時使用)
  Future<void> clearAll();
}
