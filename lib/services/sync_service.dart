import 'package:flutter/foundation.dart';
import '../core/offline_config.dart';
import '../data/models/message.dart';
import '../data/repositories/interfaces/i_itinerary_repository.dart';
import '../data/repositories/interfaces/i_message_repository.dart';
import '../data/repositories/interfaces/i_trip_repository.dart';
import '../services/log_service.dart';
import 'interfaces/i_connectivity_service.dart';
import 'interfaces/i_sync_service.dart';
import 'interfaces/i_data_service.dart';

/// 同步服務
/// 管理本地資料與 Google Sheets 的雙向同步
class SyncService implements ISyncService {
  final IDataService _sheetsService;
  final ITripRepository _tripRepo;
  final IItineraryRepository _itineraryRepo;
  final IMessageRepository _messageRepo;
  final IConnectivityService _connectivity;

  SyncService({
    required IDataService sheetsService,
    required ITripRepository tripRepo,
    required IItineraryRepository itineraryRepo,
    required IMessageRepository messageRepo,
    required IConnectivityService connectivity,
  }) : _sheetsService = sheetsService,
       _tripRepo = tripRepo,
       _itineraryRepo = itineraryRepo,
       _messageRepo = messageRepo,
       _connectivity = connectivity {
    _loadLastSyncTimes();
  }

  void _loadLastSyncTimes() {
    _lastItinerarySyncTime = _itineraryRepo.getLastSyncTime();
    _lastMessagesSyncTime = _messageRepo.getLastSyncTime();
  }

  bool get _isOffline => _connectivity.isOffline;

  /// 取得當前活動行程 ID
  String? get _activeTripId => _tripRepo.getActiveTrip()?.id;

  DateTime? _lastItinerarySyncTime;
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

    // Case 0: 兩者皆不需要 (被節流)
    if (!itinNeeded && !msgNeeded) {
      LogService.info('Auto-sync throttled (All cool)', source: 'SyncService');
      return SyncResult(isSuccess: true, itinerarySynced: false, messagesSynced: false, syncedAt: now);
    }

    // Case 1: 兩者皆需要 -> 使用 fetchAll (節省一次請求)
    if (itinNeeded && msgNeeded) {
      final tripId = _activeTripId;
      LogService.info(
        'SyncAll: Fetching ALL (Itinerary + Messages)${tripId != null ? " for trip: $tripId" : ""}',
        source: 'SyncService',
      );
      final fetchResult = await _sheetsService.getAll(tripId: tripId);

      if (!fetchResult.isSuccess) {
        return SyncResult(isSuccess: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: now);
      }

      var itinSuccess = false;
      var msgSuccess = false;
      final errors = <String>[];

      // 處理行程
      try {
        await _itineraryRepo.syncFromCloud(fetchResult.itinerary);
        _lastItinerarySyncTime = DateTime.now();
        await _itineraryRepo.saveLastSyncTime(_lastItinerarySyncTime!);
        itinSuccess = true;
      } catch (e) {
        errors.add('行程同步失敗: $e');
      }

      // 處理留言
      try {
        await _syncMessages(fetchResult.messages);
        _lastMessagesSyncTime = DateTime.now();
        await _messageRepo.saveLastSyncTime(_lastMessagesSyncTime!);
        msgSuccess = true;
      } catch (e) {
        errors.add('留言同步失敗: $e');
      }

      return SyncResult(
        isSuccess: errors.isEmpty,
        itinerarySynced: itinSuccess,
        messagesSynced: msgSuccess,
        errors: errors,
        syncedAt: DateTime.now(),
      );
    }

    // Case 2: 僅需行程
    if (itinNeeded) {
      LogService.info('SyncAll: Fetching Itinerary only', source: 'SyncService');
      return await syncItinerary(isAuto: isAuto);
    }

    // Case 3: 僅需留言
    if (msgNeeded) {
      LogService.info('SyncAll: Fetching Messages only', source: 'SyncService');
      return await syncMessages(isAuto: isAuto);
    }

    // 理論上不會執行到這裡
    return SyncResult(isSuccess: true, syncedAt: now);
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

    final tripId = _activeTripId;
    final fetchResult = await _sheetsService.getItinerary(tripId: tripId);

    if (!fetchResult.isSuccess) {
      return SyncResult(isSuccess: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: DateTime.now());
    }

    try {
      await _itineraryRepo.syncFromCloud(fetchResult.itinerary);
      _lastItinerarySyncTime = DateTime.now();
      await _itineraryRepo.saveLastSyncTime(_lastItinerarySyncTime!);
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

    final tripId = _activeTripId;
    final fetchResult = await _sheetsService.getMessages(tripId: tripId);

    if (!fetchResult.isSuccess) {
      return SyncResult(isSuccess: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: DateTime.now());
    }

    try {
      await _syncMessages(fetchResult.messages);
      _lastMessagesSyncTime = DateTime.now();
      await _messageRepo.saveLastSyncTime(_lastMessagesSyncTime!);
      return SyncResult(isSuccess: true, messagesSynced: true, syncedAt: _lastMessagesSyncTime!);
    } catch (e) {
      return SyncResult(isSuccess: false, errors: ['留言同步失敗: $e'], syncedAt: DateTime.now());
    }
  }

  /// 新增留言並同步到雲端
  /// 注意：離線模式下 UI 層應禁用此功能
  @override
  Future<ApiResult> addMessageAndSync(Message message) async {
    await _messageRepo.addMessage(message);
    final result = await _sheetsService.addMessage(message);
    LogService.info('留言已同步: ${message.uuid}', source: 'SyncService');
    return result;
  }

  /// 刪除留言並同步到雲端
  /// 注意：離線模式下 UI 層應禁用此功能
  @override
  Future<ApiResult> deleteMessageAndSync(String uuid) async {
    await _messageRepo.deleteByUuid(uuid);
    final result = await _sheetsService.deleteMessage(uuid);
    LogService.info('留言已刪除: $uuid', source: 'SyncService');
    return result;
  }

  SyncResult _offlineSyncResult() {
    return SyncResult(isSuccess: false, errors: ['目前為離線模式，無法同步'], syncedAt: DateTime.now());
  }

  ApiResult returnApiResult({required bool isSuccess, String? message}) {
    // Helper to return ApiResult since it's defined in google_sheets_service.dart
    // Assuming ApiResult constructor is public
    return ApiResult(isSuccess: isSuccess, errorMessage: isSuccess ? null : message);
  }

  /// 內部方法：單向同步留言 (雲端覆蓋本地)
  Future<void> _syncMessages(List<Message> cloudMessages) async {
    // 直接使用雲端資料覆蓋本地，不上傳本地留言
    await _messageRepo.syncFromCloud(cloudMessages);
    LogService.info('留言已從雲端同步 (${cloudMessages.length} 則)', source: 'SyncService');
  }

  /// 檢查行程衝突
  /// 回傳 true 表示有衝突 (雲端資料與本地不一致)
  @override
  Future<bool> checkItineraryConflict() async {
    final tripId = _activeTripId;
    final fetchResult = await _sheetsService.getAll(tripId: tripId);

    if (!fetchResult.isSuccess) {
      // 若無法取得雲端資料，視為無衝突 (或拋出錯誤，這裡選擇保守策略: 讓用戶決定是否硬上傳)
      // 但為了安全，若連線失敗應無法上傳，故回傳 false 讓上傳流程繼續但因為連線失敗而報錯
      // 這裡僅做比對。若 fetch 失敗，通常後續上傳也會失敗。
      return false;
    }

    final cloudItems = fetchResult.itinerary;
    final localItems = _itineraryRepo.getAllItems();

    // 簡單比對: 數量不同 -> 衝突
    if (cloudItems.length != localItems.length) return true;

    // 內容比對: 排序後逐一比對 key fields (day, name, estTime)
    // 忽略 actualTime, altitude, distance (因為這些可能本地較新)
    // 但用戶要求「覆蓋」，表示本地為準。
    // 這邊的衝突定義是：「雲端是否被其他人改過？」
    // 如果雲端跟本地不一樣，就可能是被改過，或者本地改過。
    // 用戶的情境是：本地改了，想上傳，但怕覆蓋掉雲端別人的修改。
    // 所以只要不一樣，就是衝突。

    // 建立比較用的字串列表
    final cloudStrings = cloudItems.map((e) => '${e.day}_${e.name}_${e.estTime}').toSet();
    final localStrings = localItems.map((e) => '${e.day}_${e.name}_${e.estTime}').toSet();

    // Debug Logs for Conflict
    if (!setEquals(cloudStrings, localStrings)) {
      LogService.info('Conflict Detected!', source: 'SyncService');
      LogService.info('Cloud (${cloudStrings.length}): $cloudStrings', source: 'SyncService');
      LogService.info('Local (${localStrings.length}): $localStrings', source: 'SyncService');

      final diffLocal = localStrings.difference(cloudStrings);
      final diffCloud = cloudStrings.difference(localStrings);
      if (diffLocal.isNotEmpty) LogService.info('In Local only: $diffLocal', source: 'SyncService');
      if (diffCloud.isNotEmpty) LogService.info('In Cloud only: $diffCloud', source: 'SyncService');
    }

    return !setEquals(cloudStrings, localStrings);
  }

  /// 強制上傳行程 (覆寫雲端)
  @override
  Future<SyncResult> uploadItinerary() async {
    final tripId = _activeTripId;
    final localItems = _itineraryRepo.getAllItems().where((item) => item.tripId == tripId).toList();
    final result = await _sheetsService.updateItinerary(localItems);
    if (result.isSuccess) {
      return SyncResult.success(itinerarySynced: true, messagesSynced: false);
    } else {
      return SyncResult.failure(result.errorMessage ?? 'Failed to upload itinerary');
    }
  }

  /// 取得雲端行程列表
  @override
  Future<FetchTripsResult> fetchCloudTrips() async {
    if (_isOffline) {
      return FetchTripsResult(isSuccess: false, errorMessage: '離線模式無法取得行程列表');
    }
    return await _sheetsService.getTrips();
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
