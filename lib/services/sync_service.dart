import 'package:flutter/foundation.dart';
import '../data/models/message.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/message_repository.dart';
import '../services/log_service.dart';
import 'google_sheets_service.dart';
import '../data/repositories/settings_repository.dart';

/// 同步服務
/// 管理本地資料與 Google Sheets 的雙向同步
class SyncService {
  final GoogleSheetsService _sheetsService;
  final ItineraryRepository _itineraryRepo;
  final MessageRepository _messageRepo;
  final SettingsRepository _settingsRepo;

  SyncService({
    required GoogleSheetsService sheetsService,
    required ItineraryRepository itineraryRepo,
    required MessageRepository messageRepo,
    required SettingsRepository settingsRepo,
  }) : _sheetsService = sheetsService,
       _itineraryRepo = itineraryRepo,
       _messageRepo = messageRepo,
       _settingsRepo = settingsRepo {
     _loadLastSyncTimes();
   }

   void _loadLastSyncTimes() {
     _lastItinerarySyncTime = _itineraryRepo.getLastSyncTime();
     _lastMessagesSyncTime = _messageRepo.getLastSyncTime();
   }

  bool get _isOffline => _settingsRepo.getSettings().isOfflineMode;

  DateTime? _lastItinerarySyncTime;
  DateTime? _lastMessagesSyncTime;
  static const Duration _kAutoSyncCooldown = Duration(minutes: 5);

  DateTime? get lastItinerarySync => _lastItinerarySyncTime;
  DateTime? get lastMessagesSync => _lastMessagesSyncTime;

  /// 完整同步 (下載 + 上傳)
  /// 智慧選擇：若兩者皆需更新則使用 fetchAll，否則個別更新
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();

    // 檢查冷卻時間
    // 若非自動同步 (手動)，則忽略冷卻時間 (視為已冷卻/需更新)
    final itinNeeded =
        !isAuto || (_lastItinerarySyncTime == null || now.difference(_lastItinerarySyncTime!) > _kAutoSyncCooldown);
    final msgNeeded =
        !isAuto || (_lastMessagesSyncTime == null || now.difference(_lastMessagesSyncTime!) > _kAutoSyncCooldown);

    // Case 0: 兩者皆不需要 (被節流)
    if (!itinNeeded && !msgNeeded) {
      LogService.info('Auto-sync throttled (All cool)', source: 'SyncService');
      return SyncResult(success: true, itinerarySynced: false, messagesSynced: false, syncedAt: now);
    }

    // Case 1: 兩者皆需要 -> 使用 fetchAll (節省一次請求)
    if (itinNeeded && msgNeeded) {
      LogService.info('SyncAll: Fetching ALL (Itinerary + Messages)', source: 'SyncService');
      final fetchResult = await _sheetsService.fetchAll();

      if (!fetchResult.success) {
        return SyncResult(success: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: now);
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
        success: errors.isEmpty,
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
    return SyncResult(success: true, syncedAt: now);
  }

  /// 僅同步行程
  Future<SyncResult> syncItinerary({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();
    if (isAuto && _lastItinerarySyncTime != null && now.difference(_lastItinerarySyncTime!) < _kAutoSyncCooldown) {
      final remaining = (_kAutoSyncCooldown - now.difference(_lastItinerarySyncTime!)).inSeconds;
      LogService.info('行程同步跳過 (節流中，剩餘 ${remaining}s)', source: 'SyncService');
      return SyncResult(success: true, itinerarySynced: false, syncedAt: _lastItinerarySyncTime!);
    }

    final fetchResult = await _sheetsService.fetchItinerary();

    if (!fetchResult.success) {
      return SyncResult(success: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: DateTime.now());
    }

    try {
      await _itineraryRepo.syncFromCloud(fetchResult.itinerary);
      _lastItinerarySyncTime = DateTime.now();
      await _itineraryRepo.saveLastSyncTime(_lastItinerarySyncTime!);
      return SyncResult(success: true, itinerarySynced: true, syncedAt: _lastItinerarySyncTime!);
    } catch (e) {
      return SyncResult(success: false, errors: ['行程同步失敗: $e'], syncedAt: DateTime.now());
    }
  }

  /// 僅同步留言
  Future<SyncResult> syncMessages({bool isAuto = false}) async {
    if (_isOffline) return _offlineSyncResult();

    final now = DateTime.now();
    if (isAuto && _lastMessagesSyncTime != null && now.difference(_lastMessagesSyncTime!) < _kAutoSyncCooldown) {
      final remaining = (_kAutoSyncCooldown - now.difference(_lastMessagesSyncTime!)).inSeconds;
      LogService.info('留言同步跳過 (節流中，剩餘 ${remaining}s)', source: 'SyncService');
      return SyncResult(success: true, messagesSynced: false, syncedAt: _lastMessagesSyncTime!);
    }

    final fetchResult = await _sheetsService.fetchMessages();

    if (!fetchResult.success) {
      return SyncResult(success: false, errors: [fetchResult.errorMessage ?? '網路連線失敗'], syncedAt: DateTime.now());
    }

    try {
      await _syncMessages(fetchResult.messages);
      _lastMessagesSyncTime = DateTime.now();
      await _messageRepo.saveLastSyncTime(_lastMessagesSyncTime!);
      return SyncResult(success: true, messagesSynced: true, syncedAt: _lastMessagesSyncTime!);
    } catch (e) {
      return SyncResult(success: false, errors: ['留言同步失敗: $e'], syncedAt: DateTime.now());
    }
  }

  /// 新增留言並同步到雲端
  Future<ApiResult> addMessageAndSync(Message message) async {
    // 1. 先存到本地
    await _messageRepo.addMessage(message);

    if (_isOffline) {
      LogService.info('離線模式：跳過留言上傳', source: 'SyncService');
      return returnApiResult(success: true, message: '已儲存至本地 (離線模式)');
    }

    // 2. 上傳到雲端
    final result = await _sheetsService.addMessage(message);

    if (!result.success) {
      // TODO: 實作離線佇列，稍後重試
    }

    return result;
  }

  /// 刪除留言並同步到雲端
  Future<ApiResult> deleteMessageAndSync(String uuid) async {
    // 1. 從本地刪除
    await _messageRepo.deleteByUuid(uuid);

    if (_isOffline) {
      LogService.info('離線模式：跳過留言刪除同步', source: 'SyncService');
      return returnApiResult(success: true, message: '已從本地刪除 (離線模式)');
    }

    // 2. 從雲端刪除
    final result = await _sheetsService.deleteMessage(uuid);

    if (!result.success) {
      // TODO: 實作離線佇列，稍後重試
    }

    return result;
  }

  SyncResult _offlineSyncResult() {
    return SyncResult(success: false, errors: ['目前為離線模式，無法同步'], syncedAt: DateTime.now());
  }

  ApiResult returnApiResult({required bool success, String? message}) {
    // Helper to return ApiResult since it's defined in google_sheets_service.dart
    // Assuming ApiResult constructor is public
    return ApiResult(success: success, errorMessage: success ? null : message);
  }

  /// 內部方法：雙向同步留言
  Future<void> _syncMessages(List<Message> cloudMessages) async {
    // 取得雲端留言的 UUID 集合
    final cloudUuids = cloudMessages.map((m) => m.uuid).toSet();

    // 1. 找出本地有但雲端沒有的留言 (待上傳)
    final pendingMessages = _messageRepo.getPendingMessages(cloudUuids);

    // 2. 上傳待同步的留言 (使用批次 API)
    if (pendingMessages.isNotEmpty) {
      LogService.info('Batch uploading ${pendingMessages.length} messages...', source: 'SyncService');
      final result = await _sheetsService.batchAddMessages(pendingMessages);
      if (!result.success) {
        LogService.error('Batch upload failed: ${result.errorMessage}', source: 'SyncService');
      }
    }

    // 3. 從雲端同步到本地 (會自動處理新增/刪除)
    await _messageRepo.syncFromCloud(cloudMessages);
  }

  /// 檢查行程衝突
  /// 回傳 true 表示有衝突 (雲端資料與本地不一致)
  Future<bool> checkItineraryConflict() async {
    final fetchResult = await _sheetsService.fetchAll();

    if (!fetchResult.success) {
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
  Future<ApiResult> uploadItinerary() async {
    final localItems = _itineraryRepo.getAllItems();
    return await _sheetsService.updateItinerary(localItems);
  }
}

/// 同步結果
class SyncResult {
  final bool success;
  final bool itinerarySynced;
  final bool messagesSynced;
  final bool pollsSynced;
  final List<String> errors;
  final DateTime syncedAt;

  SyncResult({
    required this.success,
    this.itinerarySynced = false,
    this.messagesSynced = false,
    this.pollsSynced = false,
    this.errors = const [],
    required this.syncedAt,
  });

  @override
  String toString() {
    if (success) {
      return '同步成功 (${syncedAt.toIso8601String()})';
    } else {
      return '同步失敗: ${errors.join(', ')}';
    }
  }
}
