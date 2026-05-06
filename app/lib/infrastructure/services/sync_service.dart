import 'package:injectable/injectable.dart';
import '../../core/models/paginated_list.dart';
import '../../core/offline_config.dart';
import 'package:summitmate/domain/domain.dart';
import '../../core/error/result.dart';
import '../tools/log_service.dart';
import '../database/app_database.dart';
import 'package:rxdart/rxdart.dart';

/// 同步服務
/// 管理本地資料與雲端資料的雙向同步
@LazySingleton(as: ISyncService)
class SyncService implements ISyncService {
  final ITripRepository _tripRepo;
  final IItineraryRepository _itineraryRepo;
  final IMessageRepository _messageRepo;
  final IConnectivityService _connectivity;
  final IAuthService _authService;
  final IGearRepository _gearRepo;
  final IGroupEventRepository _eventRepo;
  final AppDatabase _db;
  final _syncingTables = BehaviorSubject<Set<String>>.seeded({});

  SyncService({
    required ITripRepository tripRepo,
    required IItineraryRepository itineraryRepo,
    required IMessageRepository messageRepo,
    required IConnectivityService connectivity,
    required IAuthService authService,
    required IGearRepository gearRepo,
    required IGroupEventRepository eventRepo,
    required AppDatabase db,
  }) : _tripRepo = tripRepo,
       _itineraryRepo = itineraryRepo,
       _messageRepo = messageRepo,
       _connectivity = connectivity,
       _authService = authService,
       _gearRepo = gearRepo,
       _eventRepo = eventRepo,
       _db = db;

  bool get _isOffline => _connectivity.isOffline;

  /// 取得當前活動行程 ID
  Future<String?> get _activeTripId async {
    final result = await _tripRepo.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  /// 上次同步行程的時間 (這裡改為內部管理或交由 Repository 存取)
  DateTime? _lastItinerarySyncTime;

  /// 上次同步留言的時間
  DateTime? _lastMessagesSyncTime;

  @override
  DateTime? get lastItinerarySync => _lastItinerarySyncTime;
  @override
  DateTime? get lastMessagesSync => _lastMessagesSyncTime;

  /// 完整同步 (下載 + 上傳)
  @override
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    if (_isOffline) {
      return SyncResult.failure('目前為離線模式，無法同步');
    }

    final now = DateTime.now();

    // 檢查冷卻時間
    final itinNeeded =
        !isAuto ||
        (_lastItinerarySyncTime == null ||
            now.difference(_lastItinerarySyncTime!) > OfflineConfig.syncThrottleDuration);
    final msgNeeded =
        !isAuto ||
        (_lastMessagesSyncTime == null || now.difference(_lastMessagesSyncTime!) > OfflineConfig.syncThrottleDuration);

    if (!itinNeeded && !msgNeeded) {
      LogService.info('Auto-sync throttled (All cool)', source: 'SyncService');
      return SyncResult.skipped(reason: '同步節流中');
    }

    final tripId = await _activeTripId;
    if (tripId == null) {
      return SyncResult.failure('找不到活動行程');
    }

    LogService.info('SyncAll: Starting global sync for trip: $tripId', source: 'SyncService');

    var itinSuccess = false;
    var gearSuccess = false;
    var msgSuccess = false;
    var eventSuccess = false;
    final errors = <String>[];

    // 1. 處理行程
    if (itinNeeded) {
      _setSyncing('itinerary_items_table', true);
      try {
        final result = await _itineraryRepo.sync(tripId);
        if (result is Success) {
          _lastItinerarySyncTime = DateTime.now();
          itinSuccess = true;
        } else {
          errors.add('行程同步失敗');
        }
      } catch (e) {
        errors.add('行程同步異常: $e');
      } finally {
        _setSyncing('itinerary_items_table', false);
      }
    }

    // 2. 處理裝備
    _setSyncing('gear_items_table', true);
    try {
      final result = await _gearRepo.sync(tripId);
      if (result is Success) {
        gearSuccess = true;
      } else {
        errors.add('裝備同步失敗');
      }
    } catch (e) {
      errors.add('裝備同步異常: $e');
    } finally {
      _setSyncing('gear_items_table', false);
    }

    // 3. 處理留言
    if (msgNeeded) {
      _setSyncing('messages_table', true);
      try {
        final result = await _messageRepo.getRemoteMessages(tripId);
        if (result is Success) {
          _lastMessagesSyncTime = DateTime.now();
          msgSuccess = true;
        } else {
          errors.add('留言同步失敗');
        }
      } catch (e) {
        errors.add('留言同步異常: $e');
      } finally {
        _setSyncing('messages_table', false);
      }
    }

    // 4. 處理活動與報名
    _setSyncing('group_events_table', true);
    _setSyncing('group_event_applications_table', true);
    try {
      final result = await _eventRepo.syncEvents();
      if (result is Success) {
        eventSuccess = true;
      } else {
        errors.add('活動同步失敗');
      }
    } catch (e) {
      errors.add('活動同步異常: $e');
    } finally {
      _setSyncing('group_events_table', false);
      _setSyncing('group_event_applications_table', false);
    }

    return SyncResult(
      isSuccess: errors.isEmpty,
      itinerarySynced: itinSuccess,
      gearSynced: gearSuccess,
      messagesSynced: msgSuccess,
      eventsSynced: eventSuccess,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({int? page, int? limit}) async {
    if (_isOffline) {
      return Failure(Exception('離線模式無法取得行程列表'));
    }
    try {
      return await _tripRepo.getRemoteTrips(page: page, limit: limit);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }

  @override
  Stream<int> watchPendingSyncCount() {
    // Using customSelect as a workaround for a weird type inference issue with the generated select method
    final itineraryStream = _db
        .customSelect('SELECT COUNT(*) AS count FROM itinerary_items_table WHERE sync_status != "synced"')
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final gearStream = _db
        .customSelect('SELECT COUNT(*) AS count FROM gear_items_table WHERE sync_status != "synced"')
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final messageStream = _db
        .customSelect('SELECT COUNT(*) AS count FROM messages_table WHERE sync_status != "synced"')
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final eventStream = _db
        .customSelect('SELECT COUNT(*) AS count FROM group_events_table WHERE sync_status != "synced"')
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final applicationStream = _db
        .customSelect('SELECT COUNT(*) AS count FROM group_event_applications_table WHERE sync_status != "synced"')
        .watchSingle()
        .map((row) => row.read<int>('count'));

    return CombineLatestStream.list<int>([
      itineraryStream,
      gearStream,
      messageStream,
      eventStream,
      applicationStream,
    ]).map((counts) => counts.fold<int>(0, (sum, count) => sum + count));
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String table) {
    return Rx.combineLatest2(
      _syncingTables.stream,
      _db.customSelect('''
        SELECT
          COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as failed_count,
          COUNT(CASE WHEN sync_status != 'synced' AND sync_status != 'error' THEN 1 END) as pending_count
        FROM $table
      ''').watchSingle(),
      (syncingSet, row) {
        if (syncingSet.contains(table)) return SyncStatus.syncing;

        final failedCount = row.read<int>('failed_count');
        final pendingCount = row.read<int>('pending_count');

        if (failedCount > 0) return SyncStatus.error;
        if (pendingCount > 0) return SyncStatus.pendingUpdate;
        return SyncStatus.synced;
      },
    );
  }

  void _setSyncing(String table, bool isSyncing) {
    final current = _syncingTables.value;
    if (isSyncing) {
      _syncingTables.add({...current, table});
    } else {
      _syncingTables.add({...current}..remove(table));
    }
  }
}
