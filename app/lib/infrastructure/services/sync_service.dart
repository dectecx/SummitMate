import '../../core/offline_config.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../data/repositories/interfaces/i_message_repository.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../../domain/interfaces/i_sync_service.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../core/error/result.dart';

/// 同步服務
/// 管理本地資料與雲端資料的雙向同步
class SyncService implements ISyncService {
  final ITripRepository _tripRepo;
  final IItineraryRepository _itineraryRepo;
  final IMessageRepository _messageRepo;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  SyncService({
    required ITripRepository tripRepo,
    required IItineraryRepository itineraryRepo,
    required IMessageRepository messageRepo,
    required IConnectivityService connectivity,
    required IAuthService authService,
  }) : _tripRepo = tripRepo,
       _itineraryRepo = itineraryRepo,
       _messageRepo = messageRepo,
       _connectivity = connectivity,
       _authService = authService {
    _loadLastSyncTimes();
  }

  Future<void> _loadLastSyncTimes() async {
    _lastItinerarySyncTime = _itineraryRepo.getLastSyncTime();
    final result = await _messageRepo.getLastSyncTime();
    if (result is Success<DateTime?, Exception>) {
      _lastMessagesSyncTime = result.value;
    }
  }

  bool get _isOffline => _connectivity.isOffline;

  /// 取得當前活動行程 ID
  Future<String?> get _activeTripId async {
    final result = await _tripRepo.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  /// 上次同步行程的時間
  DateTime? _lastItinerarySyncTime;

  /// 上次同步留言的時間
  DateTime? _lastMessagesSyncTime;

  @override
  DateTime? get lastItinerarySync => _lastItinerarySyncTime;
  @override
  DateTime? get lastMessagesSync => _lastMessagesSyncTime;

  /// 完整同步 (下載 + 上傳)
  /// 智慧選擇：若兩者皆需更新則使用 fetchAll，否則個別更新
  @override
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();

    // 檢查冷卻時間
    // 若非自動同步 (手動)，則忽略冷卻時間 (視為已冷卻/需更新)
    final itinNeeded =
        !isAuto ||
        (_lastItinerarySyncTime == null ||
            now.difference(_lastItinerarySyncTime!) > OfflineConfig.syncThrottleDuration);
    final msgNeeded =
        !isAuto ||
        (_lastMessagesSyncTime == null || now.difference(_lastMessagesSyncTime!) > OfflineConfig.syncThrottleDuration);

    // 兩者皆不需要
    if (!itinNeeded && !msgNeeded) {
      LogService.info('Auto-sync throttled (All cool)', source: 'SyncService');
      return SyncResult(isSuccess: true, itinerarySynced: false, messagesSynced: false, syncedAt: now);
    }

    final tripId = await _activeTripId;
    if (tripId == null) {
      return SyncResult(isSuccess: false, errors: ['No active trip'], syncedAt: DateTime.now());
    }

    // 兩者皆需要 (分別呼叫 Repository 的 sync)
    LogService.info('SyncAll: Fetching Itinerary and Messages separately for trip: $tripId', source: 'SyncService');

    var itinSuccess = false;
    var msgSuccess = false;
    final errors = <String>[];

    // 處理行程
    if (itinNeeded) {
      try {
        await _itineraryRepo.sync(tripId);
        _lastItinerarySyncTime = DateTime.now();
        itinSuccess = true;
      } catch (e) {
        errors.add('行程同步失敗: $e');
      }
    }

    // 處理留言
    if (msgNeeded) {
      try {
        await _messageRepo.sync(tripId);
        _lastMessagesSyncTime = DateTime.now();
        msgSuccess = true;
      } catch (e) {
        errors.add('留言同步失敗: $e');
      }
    }

    return SyncResult(
      isSuccess: errors.isEmpty,
      itinerarySynced: itinSuccess,
      messagesSynced: msgSuccess,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  /// 僅同步行程
  @override
  Future<SyncResult> syncItinerary({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();
    if (isAuto &&
        _lastItinerarySyncTime != null &&
        now.difference(_lastItinerarySyncTime!) < OfflineConfig.syncThrottleDuration) {
      final remaining = (OfflineConfig.syncThrottleDuration - now.difference(_lastItinerarySyncTime!)).inSeconds;
      LogService.info('行程同步跳過 (節流中，剩餘 ${remaining}s)', source: 'SyncService');
      return SyncResult(isSuccess: true, itinerarySynced: false, syncedAt: _lastItinerarySyncTime!);
    }

    final tripId = await _activeTripId;
    if (tripId == null) {
      return SyncResult(isSuccess: false, errors: ['No active trip'], syncedAt: DateTime.now());
    }

    try {
      await _itineraryRepo.sync(tripId);
      _lastItinerarySyncTime = DateTime.now();
      return SyncResult(isSuccess: true, itinerarySynced: true, syncedAt: _lastItinerarySyncTime!);
    } catch (e) {
      return SyncResult(isSuccess: false, errors: ['行程同步失敗: $e'], syncedAt: DateTime.now());
    }
  }

  /// 僅同步留言
  @override
  Future<SyncResult> syncMessages({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();
    if (isAuto &&
        _lastMessagesSyncTime != null &&
        now.difference(_lastMessagesSyncTime!) < OfflineConfig.syncThrottleDuration) {
      final remaining = (OfflineConfig.syncThrottleDuration - now.difference(_lastMessagesSyncTime!)).inSeconds;
      LogService.info('留言同步跳過 (節流中，剩餘 ${remaining}s)', source: 'SyncService');
      return SyncResult(isSuccess: true, messagesSynced: false, syncedAt: _lastMessagesSyncTime!);
    }

    final tripId = await _activeTripId;
    if (tripId == null) {
      return SyncResult(isSuccess: false, errors: ['No active trip'], syncedAt: DateTime.now());
    }

    try {
      await _messageRepo.sync(tripId);
      _lastMessagesSyncTime = DateTime.now();
      return SyncResult(isSuccess: true, messagesSynced: true, syncedAt: _lastMessagesSyncTime!);
    } catch (e) {
      return SyncResult(isSuccess: false, errors: ['留言同步失敗: $e'], syncedAt: DateTime.now());
    }
  }

  /// 新增留言並同步到雲端
  /// 注意：離線模式下 UI 層應禁用此功能
  @override
  Future<Result<void, Exception>> addMessageAndSync(Message message) async {
    final result = await _messageRepo.addMessage(message);
    LogService.info('Message processed (add): ${message.id}', source: 'SyncService');
    return result;
  }

  /// 刪除留言並同步到雲端
  /// 注意：離線模式下 UI 層應禁用此功能
  @override
  Future<Result<void, Exception>> deleteMessageAndSync(String id) async {
    final result = await _messageRepo.deleteById(id);
    LogService.info('Message processed (delete): $id', source: 'SyncService');
    return result;
  }

  SyncResult _offlineSyncResult() {
    return SyncResult(isSuccess: false, errors: ['目前為離線模式，無法同步'], syncedAt: DateTime.now());
  }

  /// 檢查行程衝突 (目前由後端自動處理，預設無衝突)
  @override
  Future<bool> checkItineraryConflict() async {
    return false;
  }

  /// 強制上傳行程 (直接調用同步)
  @override
  Future<SyncResult> uploadItinerary() async {
    return await syncItinerary();
  }

  /// 取得雲端行程列表
  @override
  Future<Result<List<Trip>, Exception>> getCloudTrips() async {
    if (_isOffline) {
      return Failure(GeneralException('離線模式無法取得行程列表'));
    }
    try {
      return await _tripRepo.getRemoteTrips();
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<SyncResult> uploadPendingMessages() async {
    // 目前實作為同步留言
    return await syncMessages();
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }
}
