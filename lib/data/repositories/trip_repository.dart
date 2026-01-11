import '../models/trip.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_trip_repository.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';
import '../../domain/interfaces/i_auth_service.dart';

/// 行程 Repository (支援離線優先)
///
/// 預設使用本地資料來源 (LocalDataSource)，並可選擇性同步至遠端資料來源 (RemoteDataSource)。
class TripRepository implements ITripRepository {
  static const String _source = 'TripRepository';

  final ITripLocalDataSource _localDataSource;
  final ITripRemoteDataSource _remoteDataSource;
  final IAuthService _authService;

  TripRepository({
    required ITripLocalDataSource localDataSource,
    required ITripRemoteDataSource remoteDataSource,
    required IAuthService authService,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _authService = authService;

  /// 初始化本地資料庫
  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  /// 取得所有本地行程
  @override
  List<Trip> getAllTrips() {
    return _localDataSource.getAllTrips();
  }

  /// 取得當前活動行程
  @override
  Trip? getActiveTrip() {
    return _localDataSource.getActiveTrip();
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

    // 填寫審計欄位 (Audit Fields)
    final user = await _authService.getCachedUserProfile();
    if (user != null) {
      trip.createdBy ??= user.email;
      trip.updatedBy = user.email;
    }

    await _localDataSource.addTrip(trip);

    // Optional: Attempt immediate sync if online?
    // For now, we stay consistent with basic "Local First, Manual Sync" pattern unless requested.
  }

  /// 更新行程 (本地)
  ///
  /// [trip] 更新後的行程物件
  @override
  Future<void> updateTrip(Trip trip) async {
    // 填寫審計欄位 (Audit Fields)
    final user = await _authService.getCachedUserProfile();
    if (user != null) {
      trip.updatedBy = user.email;
    }
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
}
