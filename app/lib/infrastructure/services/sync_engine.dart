import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:summitmate/core/env_config.dart';
import 'package:summitmate/core/offline_config.dart';
import 'package:summitmate/domain/domain.dart';
import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../../data/datasources/interfaces/i_trip_remote_data_source.dart';
import '../database/app_database.dart';
import '../tools/log_service.dart';

/// 同步引擎實作（通用註冊式）
///
/// 引擎本身**不認識任何領域**：它只依序編排所有已註冊的 [ISyncAdapter]，
/// 先推送（Push）所有 C 模式表的待同步資料，再拉取（Pull）並 LWW 合併。
/// 新增可同步領域時，只需新增一個 adapter 並在 `SyncModule` 註冊，無需改動本檔。
///
/// 另保留行程的手動雲端操作（瀏覽／上傳／刪除），這些屬獨立的 A 模式 API，
/// 與通用同步週期分離。
@LazySingleton(as: ISyncEngine)
class SyncEngine implements ISyncEngine {
  final List<ISyncAdapter> _adapters;
  final ISettingsRepository _settingsRepo;
  final IConnectivityService _connectivity;
  final IAuthService _authService;
  final AppDatabase _db;

  // 行程手動雲端操作所需（與通用同步週期無關）
  final ITripRepository _tripRepo;
  final ITripRemoteDataSource _tripRemoteDataSource;

  final _syncingTables = BehaviorSubject<Set<String>>.seeded({});
  Completer<SyncResult>? _syncCompleter;
  Timer? _autoSyncTimer;
  StreamSubscription<void>? _settingsSubscription;

  SyncEngine({
    required List<ISyncAdapter> adapters,
    required ISettingsRepository settingsRepo,
    required IConnectivityService connectivity,
    required IAuthService authService,
    required AppDatabase db,
    required ITripRepository tripRepo,
    required ITripRemoteDataSource tripRemoteDataSource,
  }) : _adapters = adapters,
       _settingsRepo = settingsRepo,
       _connectivity = connectivity,
       _authService = authService,
       _db = db,
       _tripRepo = tripRepo,
       _tripRemoteDataSource = tripRemoteDataSource {
    _settingsSubscription = _settingsRepo.watchSettings().listen((_) {
      reconfigureAutoSync();
    });
    reconfigureAutoSync();
  }

  @override
  Future<SyncResult> runSyncCycle({bool force = false}) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId == 'guest') {
      LogService.info('SyncEngine: 訪客或未登入狀態，跳過雲端同步', source: 'SyncEngine');
      return SyncResult.failure('訪客或未登入狀態，跳過雲端同步');
    }

    if (_connectivity.isOffline) {
      return SyncResult.failure('目前為離線模式，無法同步');
    }

    if (_syncCompleter != null) {
      return _syncCompleter!.future;
    }

    _syncCompleter = Completer<SyncResult>();

    try {
      LogService.info('SyncEngine: Starting synchronization cycle...', source: 'SyncEngine');

      final pushResult = await pushPending();
      final pullResult = await pullRemote();

      final success = pushResult.isSuccess && pullResult.isSuccess;
      final errors = <String>[...pushResult.errors, ...pullResult.errors];

      final finalResult = SyncResult(
        isSuccess: success,
        pushedCount: pushResult.pushedCount,
        pulledCount: pullResult.pulledCount,
        conflictCount: pullResult.conflictCount,
        idMigrationsCount: pushResult.idMigrationsCount,
        errors: errors,
        errorMessage: errors.isNotEmpty ? errors.join(', ') : null,
        syncedAt: DateTime.now(),
      );

      if (success) {
        await _settingsRepo.updateLastSyncTime(DateTime.now());
      }

      _syncCompleter!.complete(finalResult);
      return finalResult;
    } catch (e) {
      final failResult = SyncResult.failure('同步發生異常: $e');
      _syncCompleter!.complete(failResult);
      return failResult;
    } finally {
      _syncCompleter = null;
    }
  }

  @override
  Future<SyncResult> pushPending() async {
    var aggregate = const SyncPushResult();

    for (final adapter in _adapters) {
      _setSyncing(adapter.tableName, true);
      try {
        aggregate = aggregate + await adapter.pushPending();
      } catch (e) {
        aggregate = aggregate + SyncPushResult(errors: ['推送 ${adapter.tableName} 時發生異常: $e']);
      } finally {
        _setSyncing(adapter.tableName, false);
      }
    }

    return SyncResult(
      isSuccess: aggregate.isSuccess,
      pushedCount: aggregate.pushedCount,
      idMigrationsCount: aggregate.idMigrationsCount,
      errors: aggregate.errors,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<SyncResult> pullRemote() async {
    var aggregate = const SyncMergeResult();

    for (final adapter in _adapters) {
      _setSyncing(adapter.tableName, true);
      try {
        aggregate = aggregate + await adapter.pullRemote();
      } catch (e) {
        aggregate = aggregate + SyncMergeResult(errors: ['拉取 ${adapter.tableName} 時發生異常: $e']);
      } finally {
        _setSyncing(adapter.tableName, false);
      }
    }

    return SyncResult(
      isSuccess: aggregate.isSuccess,
      pulledCount: aggregate.pulledCount,
      conflictCount: aggregate.conflictCount,
      errors: aggregate.errors,
      syncedAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────
  // 行程手動雲端操作 (A 模式，與通用同步週期分離)
  // ──────────────────────────────────────────

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({int? page, int? limit}) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId == 'guest') {
      return Failure(Exception('訪客或未登入狀態，無法取得雲端行程列表'));
    }
    if (_connectivity.isOffline) {
      return Failure(Exception('離線模式無法取得行程列表'));
    }
    try {
      final result = await _tripRemoteDataSource.getRemoteTrips(page: page, limit: limit);
      if (result is Success<PaginatedList<Trip>, Exception>) {
        for (final trip in result.value.items) {
          await _tripRepo.saveTrip(trip.copyWith(syncStatus: SyncStatus.synced));
        }
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> uploadToCloud(Trip trip) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId == 'guest') {
      return Failure(Exception('訪客或未登入狀態，無法上傳行程至雲端'));
    }
    if (_connectivity.isOffline) {
      return Failure(Exception('離線模式無法上傳'));
    }
    return _tripRemoteDataSource.uploadTrip(trip);
  }

  @override
  Future<Result<void, Exception>> removeFromCloud(String tripId) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId == 'guest') {
      return Failure(Exception('訪客或未登入狀態，無法自雲端刪除行程'));
    }
    if (_connectivity.isOffline) {
      return Failure(Exception('離線模式無法刪除'));
    }
    return _tripRemoteDataSource.deleteTrip(tripId);
  }

  // ──────────────────────────────────────────
  // 觀測 / 自動同步 / 生命週期
  // ──────────────────────────────────────────

  @override
  void resetLastSyncTimes() {
    _settingsRepo.updateLastSyncTime(null);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final settings = await _settingsRepo.getSettings();
    return settings.lastSyncTime;
  }

  @override
  void reconfigureAutoSync() async {
    try {
      final settings = await _settingsRepo.getSettings();
      final rawMinutes = settings.autoSyncIntervalMinutes;
      final minutes = OfflineConfig.clampAutoSyncInterval(rawMinutes, isDevMode: EnvConfig.isDev);

      stopAutoSync();

      if (minutes > 0) {
        LogService.info('SyncEngine: Configuring auto-sync every $minutes minutes', source: 'SyncEngine');
        _autoSyncTimer = Timer.periodic(Duration(minutes: minutes), (timer) {
          runSyncCycle(force: false);
        });
      } else {
        LogService.info('SyncEngine: Auto-sync is disabled', source: 'SyncEngine');
      }
    } catch (e) {
      LogService.error('SyncEngine reconfigureAutoSync failed: $e', source: 'SyncEngine');
    }
  }

  @override
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  @override
  void dispose() {
    stopAutoSync();
    _settingsSubscription?.cancel();
    _syncingTables.close();
  }

  @override
  Stream<int> watchPendingSyncCount() {
    // 依已註冊 adapter 的表名動態組成單一 UNION ALL 查詢，
    // 避免多個獨立 Stream 造成並發查詢風暴。
    final names = _adapters.map((a) => a.tableName).toList();
    final union = names
        .map((n) => "SELECT COUNT(*) AS cnt FROM $n WHERE sync_status != 'synced'")
        .join('\n        UNION ALL\n        ');
    final readsFrom = _db.allTables.where((t) => names.contains(t.actualTableName)).toSet();

    return _db
        .customSelect('SELECT SUM(cnt) AS total FROM (\n        $union\n      )', readsFrom: readsFrom)
        .watchSingle()
        .map((row) => row.read<int>('total'));
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
