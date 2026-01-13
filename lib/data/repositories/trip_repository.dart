import '../../core/error/result.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_trip_repository.dart';
import '../datasources/interfaces/i_trip_local_data_source.dart';
import '../datasources/interfaces/i_trip_remote_data_source.dart';
import '../models/user_profile.dart';
import '../models/trip.dart';

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
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      LogService.error('Init failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得所有本地行程 (僅限目前登入使用者)
  @override
  Future<Result<List<Trip>, Exception>> getAllTrips(String userId) async {
    try {
      final trips = _localDataSource.getAllTrips().where((t) => t.userId == userId).toList();
      return Success(trips);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得當前活動行程 (僅限目前登入使用者)
  @override
  Future<Result<Trip?, Exception>> getActiveTrip(String userId) async {
    try {
      final trip = _localDataSource.getActiveTrip();
      if (trip != null && trip.userId == userId) {
        return Success(trip);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 根據 ID 取得行程
  ///
  /// [id] 行程 ID
  @override
  Future<Result<Trip?, Exception>> getTripById(String id) async {
    try {
      return Success(_localDataSource.getTripById(id));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 新增行程 (本地)
  ///
  /// [trip] 欲新增的行程物件
  @override
  Future<Result<void, Exception>> addTrip(Trip trip) async {
    try {
      LogService.info('Adding trip: ${trip.name} (Local)', source: _source);
      await _localDataSource.addTrip(trip);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 更新行程 (本地)
  ///
  /// [trip] 更新後的行程物件
  @override
  Future<Result<void, Exception>> updateTrip(Trip trip) async {
    try {
      await _localDataSource.updateTrip(trip);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 刪除行程 (本地)
  ///
  /// [id] 欲刪除的行程 ID
  @override
  Future<Result<void, Exception>> deleteTrip(String id) async {
    try {
      await _localDataSource.deleteTrip(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 設定當前活動行程
  ///
  /// [tripId] 要設為 Active 的行程 ID
  @override
  Future<Result<void, Exception>> setActiveTrip(String tripId) async {
    try {
      await _localDataSource.setActiveTrip(tripId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得最後同步時間 (暫未實作)
  @override
  Future<Result<DateTime?, Exception>> getLastSyncTime() async {
    // Moved to Settings or Metadata repository if needed, or kept here if we implement sync timestamps in LocalDataSource
    return const Success(null);
  }

  /// 儲存最後同步時間 (暫未實作)
  ///
  /// [time] 同步時間
  @override
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time) async {
    return const Success(null);
  }

  /// 取得雲端行程列表
  @override
  Future<Result<List<Trip>, Exception>> getRemoteTrips() async {
    try {
      return Success(await _remoteDataSource.getTrips());
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 上傳行程至雲端
  ///
  /// [trip] 欲上傳的行程
  /// 回傳: 上傳結果訊息
  @override
  Future<Result<String, Exception>> uploadTripToRemote(Trip trip) async {
    try {
      return Success(await _remoteDataSource.uploadTrip(trip));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 刪除雲端行程
  ///
  /// [id] 欲刪除的遠端行程 ID
  @override
  Future<Result<void, Exception>> deleteRemoteTrip(String id) async {
    try {
      await _remoteDataSource.deleteTrip(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 完整備份行程至雲端 (包含細節與裝備)
  ///
  /// [trip] 行程物件
  /// [itineraryItems] 行程節點列表
  /// [gearItems] 裝備列表
  /// 回傳: 上傳結果訊息
  @override
  Future<Result<String, Exception>> uploadFullTrip({
    required Trip trip,
    required List<dynamic> itineraryItems,
    required List<dynamic> gearItems,
  }) async {
    try {
      return Success(
        await _remoteDataSource.uploadFullTrip(trip: trip, itineraryItems: itineraryItems, gearItems: gearItems),
      );
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 清除所有本地行程
  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all trips (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得行程成員列表
  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getTripMembers(String tripId) async {
    try {
      return Success(await _remoteDataSource.getTripMembers(tripId));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 更新成員角色
  @override
  Future<Result<void, Exception>> updateMemberRole(String tripId, String userId, String role) async {
    try {
      await _remoteDataSource.updateMemberRole(tripId, userId, role);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 移除成員
  @override
  Future<Result<void, Exception>> removeMember(String tripId, String userId) async {
    try {
      await _remoteDataSource.removeMember(tripId, userId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 新增成員 (透過 Email)
  @override
  Future<Result<void, Exception>> addMemberByEmail(String tripId, String email, {String role = 'member'}) async {
    try {
      await _remoteDataSource.addMemberByEmail(tripId, email, role: role);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 新增成員 (透過 User ID)
  @override
  Future<Result<void, Exception>> addMemberById(String tripId, String userId, {String role = 'member'}) async {
    try {
      await _remoteDataSource.addMemberById(tripId, userId, role: role);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 搜尋使用者
  @override
  Future<Result<UserProfile, Exception>> searchUserByEmail(String email) async {
    try {
      return Success(await _remoteDataSource.searchUserByEmail(email));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<UserProfile, Exception>> searchUserById(String userId) async {
    try {
      return Success(await _remoteDataSource.searchUserById(userId));
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
