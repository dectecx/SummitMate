import 'package:hive/hive.dart';
import '../../core/di.dart';
import '../../core/error/result.dart';
import '../models/itinerary_item.dart';
import 'interfaces/i_itinerary_repository.dart';
import '../datasources/interfaces/i_itinerary_local_data_source.dart';
import '../datasources/interfaces/i_itinerary_remote_data_source.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../../infrastructure/tools/log_service.dart';

/// 行程 Repository
///
/// 協調本地資料庫 (Hive) 與遠端資料來源 (API)，負責行程資料的 CRUD 與同步。
class ItineraryRepository implements IItineraryRepository {
  static const String _source = 'ItineraryRepository';

  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;
  final IConnectivityService _connectivity;

  ItineraryRepository({
    IItineraryLocalDataSource? localDataSource,
    IItineraryRemoteDataSource? remoteDataSource,
    IConnectivityService? connectivity,
  }) : _localDataSource = localDataSource ?? getIt<IItineraryLocalDataSource>(),
       _remoteDataSource = remoteDataSource ?? getIt<IItineraryRemoteDataSource>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>();

  /// 初始化 Repository (主要是本地資料庫)
  @override
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // --- 本地操作代理 ---

  /// 取得所有行程項目
  @override
  List<ItineraryItem> getAllItems() {
    return _localDataSource.getAll();
  }

  /// 依天數取得行程項目 (e.g. "D1")
  ///
  /// [day] 行程天數 (e.g., "D1")
  @override
  List<ItineraryItem> getItemsByDay(String day) {
    return _localDataSource.getAll().where((item) => item.day == day).toList();
  }

  /// 依 Key 取得單一行程項目
  ///
  /// [key] 行程節點 Key
  @override
  ItineraryItem? getItemByKey(dynamic key) {
    return _localDataSource.getByKey(key);
  }

  /// 打卡 (設定 actualTime)
  ///
  /// [key] 行程節點 Key
  /// [time] 打卡時間
  @override
  Future<Result<void, Exception>> checkIn(dynamic key, DateTime time) async {
    try {
      final item = _localDataSource.getByKey(key);
      if (item == null) return const Failure(GeneralException('Item not found'));
      item.actualTime = time;
      await _localDataSource.update(key, item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取消打卡
  ///
  /// [key] 行程節點 Key
  @override
  Future<Result<void, Exception>> clearCheckIn(dynamic key) async {
    try {
      final item = _localDataSource.getByKey(key);
      if (item == null) return const Failure(GeneralException('Item not found'));
      item.actualTime = null;
      await _localDataSource.update(key, item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 重置所有打卡狀態
  @override
  Future<Result<void, Exception>> resetAllCheckIns() async {
    try {
      for (final item in _localDataSource.getAll()) {
        item.actualTime = null;
        await _localDataSource.update('${item.day}_${item.name}', item);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 新增行程項目 (本地)
  ///
  /// [item] 欲新增的節點
  @override
  Future<Result<void, Exception>> addItem(ItineraryItem item) async {
    try {
      await _localDataSource.add(item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 更新行程項目 (本地)
  ///
  /// [key] 目標節點 Key
  /// [item] 更新後的節點資料
  @override
  Future<Result<void, Exception>> updateItem(dynamic key, ItineraryItem item) async {
    try {
      await _localDataSource.update(key, item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 刪除行程項目 (本地)
  ///
  /// [key] 目標節點 Key
  @override
  Future<Result<void, Exception>> deleteItem(dynamic key) async {
    try {
      await _localDataSource.delete(key);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 儲存最後同步時間
  ///
  /// [time] 同步時間
  @override
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time) async {
    try {
      await _localDataSource.saveLastSyncTime(time);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    return _localDataSource.getLastSyncTime();
  }

  /// 監聽行程變更
  @override
  Stream<BoxEvent> watchAllItems() {
    return _localDataSource.watch();
  }

  // --- 同步操作 ---

  /// 同步行程 (從雲端拉取)
  ///
  /// [tripId] 行程 ID
  ///
  /// 策略：從雲端取得最新行程表，但保留本地的打卡紀錄 (actualTime)，然後覆寫本地資料。
  @override
  Future<Result<void, Exception>> sync(String tripId) async {
    if (_connectivity.isOffline) {
      LogService.warning('Offline mode, skipping itinerary sync', source: _source);
      return const Success(
        null,
      ); // Or return specific status? Treating offline sync skip as non-fatal success is common
    }

    try {
      LogService.info('Syncing itinerary for trip: $tripId', source: _source);
      final cloudItems = await _remoteDataSource.getItinerary(tripId);

      // 保存本地打卡狀態
      final existing = _localDataSource.getAll();
      final actualTimeMap = <String, DateTime?>{};
      for (final item in existing) {
        final key = '${item.day}_${item.name}';
        actualTimeMap[key] = item.actualTime;
      }

      await _localDataSource.clear();

      // 還原打卡狀態並寫入新資料
      for (final item in cloudItems) {
        final key = '${item.day}_${item.name}';
        item.actualTime = actualTimeMap[key];
        await _localDataSource.add(item);
      }

      await saveLastSyncTime(DateTime.now());
      LogService.info('Sync itinerary complete', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Sync itinerary failed: $e', source: _source);
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 從雲端列表同步 (Legacy / 直接匯入用)
  ///
  /// [cloudItems] 雲端下載的行程節點列表
  @override
  Future<Result<void, Exception>> syncFromCloud(List<ItineraryItem> cloudItems) async {
    try {
      // 保留打卡狀態邏輯
      final existing = _localDataSource.getAll();
      final actualTimeMap = <String, DateTime?>{};
      for (final item in existing) {
        final key = '${item.day}_${item.name}';
        actualTimeMap[key] = item.actualTime;
      }

      await _localDataSource.clear();

      for (final item in cloudItems) {
        final key = '${item.day}_${item.name}';
        item.actualTime = actualTimeMap[key];
        await _localDataSource.add(item);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 清除所有行程項目
  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all itinerary items (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
