import '../models/trip.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_trip_repository.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';

/// 行程 Repository (支援離線優先)
///
/// 預設使用本地資料來源 (LocalDataSource)，並可選擇性同步至遠端資料來源 (RemoteDataSource)。
class TripRepository implements ITripRepository {
  static const String _source = 'TripRepository';

  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;

  TripRepository({required ITripLocalDataSource localDataSource, required ITripRemoteDataSource remoteDataSource})
    : _localDataSource = localDataSource,
      _remoteDataSource = remoteDataSource;

  /// 初始化本地資料庫
  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  /// 取得所有本地行程 (僅限目前登入使用者)
  @override
  List<Trip> getAllTrips(String userId) {
    return _localDataSource.getAllTrips().where((t) => t.userId == userId).toList();
  }

  /// 取得當前活動行程 (僅限目前登入使用者)
  @override
  Trip? getActiveTrip(String userId) {
    final trip = _localDataSource.getActiveTrip();
    if (trip != null && trip.userId == userId) {
      return trip;
    }
    return null;
  }

  /// 根據 ID 取得行程
  ///
  /// [id] 行程 ID
  @override
  Trip? getTripById(String id) {
    return _localDataSource.getTripById(id);
  }

  /// 新增行程 (本地)
  ///
  /// [trip] 欲新增的行程物件
  @override
  Future<void> addTrip(Trip trip) async {
    LogService.info('Adding trip: ${trip.name} (Local)', source: _source);

    // 填寫審計欄位 (Audit Fields) & Ownership
    // userId, createdBy, createdAt are final and required in Trip constructor,
    // so they must be populated by the caller (Cubit/Service).

    // Ensure updatedBy matches createdBy if not set (constructor handles this default, but explicit here doesn't hurt if mutable)
    // Actually constructor matches them. logic here is redundant if constructor does it.
    // Just save.

    await _localDataSource.addTrip(trip);
  }

  /// 更新行程 (本地)
  ///
  /// [trip] 更新後的行程物件
  @override
  Future<void> updateTrip(Trip trip) async {
    // 呼叫者負責更新 updatedBy / updatedAt
    await _localDataSource.updateTrip(trip);
  }

  /// 刪除行程 (本地)
  ///
  /// [id] 欲刪除的行程 ID
  @override
  Future<void> deleteTrip(String id) async {
    await _localDataSource.deleteTrip(id);
  }

  /// 設定當前活動行程
  ///
  /// [tripId] 要設為 Active 的行程 ID
  @override
  Future<void> setActiveTrip(String tripId) async {
    await _localDataSource.setActiveTrip(tripId);
  }

  /// 取得最後同步時間 (暫未實作)
  @override
  DateTime? getLastSyncTime() {
    // Moved to Settings or Metadata repository if needed, or kept here if we implement sync timestamps in LocalDataSource
    return null;
  }

  /// 儲存最後同步時間 (暫未實作)
  ///
  /// [time] 同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    //
  }

  /// 取得雲端行程列表
  @override
  Future<List<Trip>> getRemoteTrips() async {
    return _remoteDataSource.getTrips();
  }

  /// 上傳行程至雲端
  ///
  /// [trip] 欲上傳的行程
  /// 回傳: 上傳結果訊息
  @override
  Future<String> uploadTripToRemote(Trip trip) async {
    return _remoteDataSource.uploadTrip(trip);
  }

  /// 刪除雲端行程
  ///
  /// [id] 欲刪除的遠端行程 ID
  @override
  Future<void> deleteRemoteTrip(String id) async {
    await _remoteDataSource.deleteTrip(id);
  }

  /// 完整備份行程至雲端 (包含細節與裝備)
  ///
  /// [trip] 行程物件
  /// [itineraryItems] 行程節點列表
  /// [gearItems] 裝備列表
  /// 回傳: 上傳結果訊息
  @override
  Future<String> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    return _remoteDataSource.uploadFullTrip(trip: trip, itineraryItems: itineraryItems, gearItems: gearItems);
  }

  /// 清除所有本地行程
  @override
  Future<void> clearAll() async {
    LogService.info('Clearing all trips (Local)', source: _source);
    await _localDataSource.clear();
  }

  /// 取得行程成員列表
  @override
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) {
    return _remoteDataSource.getTripMembers(tripId);
  }

  /// 更新成員角色
  @override
  Future<void> updateMemberRole(String tripId, String userId, String role) {
    return _remoteDataSource.updateMemberRole(tripId, userId, role);
  }

  /// 移除成員
  @override
  Future<void> removeMember(String tripId, String userId) {
    return _remoteDataSource.removeMember(tripId, userId);
  }
}
