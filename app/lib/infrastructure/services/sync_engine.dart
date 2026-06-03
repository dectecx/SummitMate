import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:summitmate/core/env_config.dart';
import 'package:summitmate/core/offline_config.dart';
import 'package:summitmate/domain/domain.dart';
import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../../data/datasources/interfaces/i_itinerary_local_data_source.dart';
import '../../data/datasources/interfaces/i_gear_local_data_source.dart';
import '../database/app_database.dart';
import '../tools/log_service.dart';
import 'adapters/trip_sync_adapter.dart';
import 'adapters/itinerary_sync_adapter.dart';
import '../../data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'adapters/gear_sync_adapter.dart';

/// 同步引擎實作
///
/// 負責編排本地待同步資料的推送 (Push) 與遠端最新資料的拉取與 LWW 合併 (Pull & Merge)。
/// 也負責管理基於設定的背景定時自動同步。
@LazySingleton(as: ISyncEngine)
class SyncEngine implements ISyncEngine {
  final ITripRepository _tripRepo;
  final IItineraryRepository _itineraryRepo;
  final IGearRepository _gearRepo;
  final IMessageRepository _messageRepo;
  final IGroupEventRepository _eventRepo;
  final ISettingsRepository _settingsRepo;
  final IConnectivityService _connectivity;
  final IAuthService _authService;
  final AppDatabase _db;

  final IItineraryLocalDataSource _itineraryLocalDataSource;
  final IGearLocalDataSource _gearLocalDataSource;
  final ITripRemoteDataSource _tripRemoteDataSource;

  final TripSyncAdapter _tripSyncAdapter;
  final ItinerarySyncAdapter _itinerarySyncAdapter;
  final GearSyncAdapter _gearSyncAdapter;

  final _syncingTables = BehaviorSubject<Set<String>>.seeded({});
  Completer<SyncResult>? _syncCompleter;
  Timer? _autoSyncTimer;
  StreamSubscription<void>? _settingsSubscription;

  SyncEngine({
    required ITripRepository tripRepo,
    required IItineraryRepository itineraryRepo,
    required IGearRepository gearRepo,
    required IMessageRepository messageRepo,
    required IGroupEventRepository eventRepo,
    required ISettingsRepository settingsRepo,
    required IConnectivityService connectivity,
    required IAuthService authService,
    required AppDatabase db,
    required IItineraryLocalDataSource itineraryLocalDataSource,
    required IGearLocalDataSource gearLocalDataSource,
    required ITripRemoteDataSource tripRemoteDataSource,
    required TripSyncAdapter tripSyncAdapter,
    required ItinerarySyncAdapter itinerarySyncAdapter,
    required GearSyncAdapter gearSyncAdapter,
  }) : _tripRepo = tripRepo,
       _itineraryRepo = itineraryRepo,
       _gearRepo = gearRepo,
       _messageRepo = messageRepo,
       _eventRepo = eventRepo,
       _settingsRepo = settingsRepo,
       _connectivity = connectivity,
       _authService = authService,
       _db = db,
       _itineraryLocalDataSource = itineraryLocalDataSource,
       _gearLocalDataSource = gearLocalDataSource,
       _tripRemoteDataSource = tripRemoteDataSource,
       _tripSyncAdapter = tripSyncAdapter,
       _itinerarySyncAdapter = itinerarySyncAdapter,
       _gearSyncAdapter = gearSyncAdapter {
    // 監聽設定變更，以重啟自動同步定時器
    _settingsSubscription = _settingsRepo.watchSettings().listen((_) {
      reconfigureAutoSync();
    });
    // 初始配置自動同步
    reconfigureAutoSync();
  }

  Future<String?> get _activeTripId async {
    final result = await _tripRepo.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  @override
  Future<SyncResult> runSyncCycle({bool force = false}) async {
    if (_connectivity.isOffline) {
      return SyncResult.failure('目前為離線模式，無法同步');
    }

    if (_syncCompleter != null) {
      return _syncCompleter!.future;
    }

    _syncCompleter = Completer<SyncResult>();

    try {
      LogService.info('SyncEngine: Starting synchronization cycle...', source: 'SyncEngine');

      // 1. Push pending offline changes first
      final pushResult = await pushPending();

      // 2. Pull remote changes and merge
      final pullResult = await pullRemote();

      final success = pushResult.isSuccess && pullResult.isSuccess;
      final errors = <String>[...pushResult.errors, ...pullResult.errors];

      final finalResult = SyncResult(
        isSuccess: success,
        itinerarySynced: pullResult.itinerarySynced,
        gearSynced: pullResult.gearSynced,
        messagesSynced: pullResult.messagesSynced,
        eventsSynced: pullResult.eventsSynced,
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
    final userId = _authService.currentUserId ?? 'guest';
    int pushedCount = 0;
    int idMigrationsCount = 0;
    final errors = <String>[];

    // --- 1. Push Pending Trips ---
    _setSyncing('trips_table', true);
    try {
      final tripsRes = await _tripRepo.getAllTrips(userId);
      if (tripsRes is Success<List<Trip>, Exception>) {
        final pendingTrips = tripsRes.value.where((t) => t.syncStatus != SyncStatus.synced).toList();

        // 優先排序：pendingCreate/pendingUpdate 排在 pendingDelete 前面
        pendingTrips.sort((a, b) {
          if (a.syncStatus == SyncStatus.pendingDelete && b.syncStatus != SyncStatus.pendingDelete) return 1;
          if (a.syncStatus != SyncStatus.pendingDelete && b.syncStatus == SyncStatus.pendingDelete) return -1;
          return 0;
        });

        for (final trip in pendingTrips) {
          final res = await _tripSyncAdapter.pushItem(trip, trip.syncStatus);
          if (res is Success<IdMigration?, Exception>) {
            pushedCount++;
            final migration = res.value;
            if (migration != null) {
              await _tripRepo.updateLocalTripId(migration.tempId, migration.permanentId);
              await _db.markAsSynced('trips_table', migration.permanentId);
              idMigrationsCount++;
            } else {
              if (trip.syncStatus != SyncStatus.pendingDelete) {
                await _db.markAsSynced('trips_table', trip.id);
              }
            }
          } else {
            final err = (res as Failure).exception;
            errors.add('行程 ${trip.name} 推送失敗: $err');
            await _db.markAsError('trips_table', trip.id);
          }
        }
      }
    } catch (e) {
      errors.add('推送行程列表時發生異常: $e');
    } finally {
      _setSyncing('trips_table', false);
    }

    // --- 2. Push Pending Itinerary Items ---
    _setSyncing('itinerary_items_table', true);
    try {
      final allItin = await _itineraryLocalDataSource.getAll();
      final pendingItin = allItin.where((i) => i.syncStatus != SyncStatus.synced).toList();

      for (final item in pendingItin) {
        final res = await _itinerarySyncAdapter.pushItem(item, item.syncStatus);
        if (res is Success<IdMigration?, Exception>) {
          pushedCount++;
          final migration = res.value;
          if (migration != null) {
            await _itineraryRepo.updateLocalId(migration.tempId, migration.permanentId);
            await _db.markAsSynced('itinerary_items_table', migration.permanentId);
            idMigrationsCount++;
          } else {
            if (item.syncStatus != SyncStatus.pendingDelete) {
              await _db.markAsSynced('itinerary_items_table', item.id);
            }
          }
        } else {
          final err = (res as Failure).exception;
          errors.add('行程節點 ${item.name} 推送失敗: $err');
          await _db.markAsError('itinerary_items_table', item.id);
        }
      }
    } catch (e) {
      errors.add('推送行程節點時發生異常: $e');
    } finally {
      _setSyncing('itinerary_items_table', false);
    }

    // --- 3. Push Pending Gear Items ---
    _setSyncing('gear_items_table', true);
    try {
      final allGear = await _gearLocalDataSource.getAll();
      final pendingGear = allGear.where((g) => g.syncStatus != SyncStatus.synced).toList();

      for (final item in pendingGear) {
        final res = await _gearSyncAdapter.pushItem(item, item.syncStatus);
        if (res is Success<IdMigration?, Exception>) {
          pushedCount++;
          final migration = res.value;
          if (migration != null) {
            await _gearRepo.updateLocalId(migration.tempId, migration.permanentId);
            await _db.markAsSynced('gear_items_table', migration.permanentId);
            idMigrationsCount++;
          } else {
            if (item.syncStatus != SyncStatus.pendingDelete) {
              await _db.markAsSynced('gear_items_table', item.id);
            }
          }
        } else {
          final err = (res as Failure).exception;
          errors.add('裝備 ${item.name} 推送失敗: $err');
          await _db.markAsError('gear_items_table', item.id);
        }
      }
    } catch (e) {
      errors.add('推送裝備時發生異常: $e');
    } finally {
      _setSyncing('gear_items_table', false);
    }

    return SyncResult(
      isSuccess: errors.isEmpty,
      pushedCount: pushedCount,
      idMigrationsCount: idMigrationsCount,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<SyncResult> pullRemote() async {
    final userId = _authService.currentUserId ?? 'guest';
    int pulledCount = 0;
    int conflictCount = 0;
    final errors = <String>[];

    var itinerarySynced = false;
    var gearSynced = false;
    var messagesSynced = false;
    var eventsSynced = false;

    // --- 1. Pull Trips ---
    _setSyncing('trips_table', true);
    try {
      final res = await _tripSyncAdapter.pullAndMerge(userId);
      if (res is Success<SyncMergeResult, Exception>) {
        pulledCount += res.value.pulledCount;
        conflictCount += res.value.conflictCount;
      } else {
        errors.add('拉取行程列表失敗: ${(res as Failure).exception}');
      }
    } catch (e) {
      errors.add('拉取行程列表時發生異常: $e');
    } finally {
      _setSyncing('trips_table', false);
    }

    // 獲取最新本地行程列表以同步子節點
    List<Trip> localTrips = [];
    try {
      final tripsRes = await _tripRepo.getAllTrips(userId);
      if (tripsRes is Success<List<Trip>, Exception>) {
        localTrips = tripsRes.value;
      }
    } catch (e) {
      LogService.error('獲取本地行程列表失敗: $e', source: 'SyncEngine');
    }

    // --- 2. Pull Itinerary Items ---
    _setSyncing('itinerary_items_table', true);
    try {
      for (final trip in localTrips) {
        if (trip.syncStatus == SyncStatus.pendingDelete) continue;

        final res = await _itinerarySyncAdapter.pullAndMerge(trip.id);
        if (res is Success<SyncMergeResult, Exception>) {
          pulledCount += res.value.pulledCount;
          conflictCount += res.value.conflictCount;
          itinerarySynced = true;
        } else {
          errors.add('拉取行程 ${trip.name} 的節點失敗: ${(res as Failure).exception}');
        }
      }
    } catch (e) {
      errors.add('拉取行程節點時發生異常: $e');
    } finally {
      _setSyncing('itinerary_items_table', false);
    }

    // --- 3. Pull Gear Items ---
    _setSyncing('gear_items_table', true);
    try {
      for (final trip in localTrips) {
        if (trip.syncStatus == SyncStatus.pendingDelete) continue;

        final res = await _gearSyncAdapter.pullAndMerge(trip.id);
        if (res is Success<SyncMergeResult, Exception>) {
          pulledCount += res.value.pulledCount;
          conflictCount += res.value.conflictCount;
          gearSynced = true;
        } else {
          errors.add('拉取行程 ${trip.name} 的裝備失敗: ${(res as Failure).exception}');
        }
      }
    } catch (e) {
      errors.add('拉取裝備時發生異常: $e');
    } finally {
      _setSyncing('gear_items_table', false);
    }

    // --- 4. Pull T2 Data Types (Messages & Events) for the active trip ---
    final activeTripId = await _activeTripId;
    if (activeTripId != null) {
      // Pull messages
      _setSyncing('messages_table', true);
      try {
        final res = await _messageRepo.getRemoteMessages(activeTripId);
        if (res is Success) {
          messagesSynced = true;
        } else {
          errors.add('拉取留言失敗: ${(res as Failure).exception}');
        }
      } catch (e) {
        errors.add('拉取留言時發生異常: $e');
      } finally {
        _setSyncing('messages_table', false);
      }
    }

    // Pull events
    _setSyncing('group_events_table', true);
    _setSyncing('group_event_applications_table', true);
    try {
      final res = await _eventRepo.syncEvents();
      if (res is Success) {
        eventsSynced = true;
      } else {
        errors.add('拉取活動失敗: ${(res as Failure).exception}');
      }
    } catch (e) {
      errors.add('拉取活動時發生異常: $e');
    } finally {
      _setSyncing('group_events_table', false);
      _setSyncing('group_event_applications_table', false);
    }

    return SyncResult(
      isSuccess: errors.isEmpty,
      itinerarySynced: itinerarySynced,
      gearSynced: gearSynced,
      messagesSynced: messagesSynced,
      eventsSynced: eventsSynced,
      pulledCount: pulledCount,
      conflictCount: conflictCount,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({int? page, int? limit}) async {
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
    if (_connectivity.isOffline) {
      return Failure(Exception('離線模式無法上傳'));
    }
    return _tripRemoteDataSource.uploadTrip(trip);
  }

  @override
  Future<Result<void, Exception>> removeFromCloud(String tripId) async {
    if (_connectivity.isOffline) {
      return Failure(Exception('離線模式無法刪除'));
    }
    return _tripRemoteDataSource.deleteTrip(tripId);
  }

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
    final tripStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM trips_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final itineraryStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM itinerary_items_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final gearStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM gear_items_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final messageStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM messages_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final eventStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM group_events_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    final applicationStream = _db
        .customSelect("SELECT COUNT(*) AS count FROM group_event_applications_table WHERE sync_status != 'synced'")
        .watchSingle()
        .map((row) => row.read<int>('count'));

    return CombineLatestStream.list<int>([
      tripStream,
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
