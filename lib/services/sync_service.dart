import '../data/models/message.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/message_repository.dart';
import 'google_sheets_service.dart';

/// 同步服務
/// 管理本地資料與 Google Sheets 的雙向同步
class SyncService {
  final GoogleSheetsService _sheetsService;
  final ItineraryRepository _itineraryRepo;
  final MessageRepository _messageRepo;

  SyncService({
    required GoogleSheetsService sheetsService,
    required ItineraryRepository itineraryRepo,
    required MessageRepository messageRepo,
  })  : _sheetsService = sheetsService,
        _itineraryRepo = itineraryRepo,
        _messageRepo = messageRepo;

  /// 完整同步 (下載 + 上傳)
  Future<SyncResult> syncAll() async {
    final errors = <String>[];
    var itinerarySuccess = false;
    var messagesSuccess = false;

    // 1. 從雲端拉取資料
    final fetchResult = await _sheetsService.fetchAll();
    
    if (fetchResult.success) {
      // 2. 同步行程 (雲端 -> 本地，單向)
      try {
        await _itineraryRepo.syncFromCloud(fetchResult.itinerary);
        itinerarySuccess = true;
      } catch (e) {
        errors.add('行程同步失敗: $e');
      }

      // 3. 同步留言 (雙向)
      try {
        await _syncMessages(fetchResult.messages);
        messagesSuccess = true;
      } catch (e) {
        errors.add('留言同步失敗: $e');
      }
    } else {
      errors.add(fetchResult.errorMessage ?? '網路連線失敗');
    }

    return SyncResult(
      success: itinerarySuccess && messagesSuccess && errors.isEmpty,
      itinerarySynced: itinerarySuccess,
      messagesSynced: messagesSuccess,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  /// 僅同步行程
  Future<SyncResult> syncItinerary() async {
    final fetchResult = await _sheetsService.fetchAll();
    
    if (!fetchResult.success) {
      return SyncResult(
        success: false,
        errors: [fetchResult.errorMessage ?? '網路連線失敗'],
        syncedAt: DateTime.now(),
      );
    }

    try {
      await _itineraryRepo.syncFromCloud(fetchResult.itinerary);
      return SyncResult(
        success: true,
        itinerarySynced: true,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        success: false,
        errors: ['行程同步失敗: $e'],
        syncedAt: DateTime.now(),
      );
    }
  }

  /// 僅同步留言
  Future<SyncResult> syncMessages() async {
    final fetchResult = await _sheetsService.fetchAll();
    
    if (!fetchResult.success) {
      return SyncResult(
        success: false,
        errors: [fetchResult.errorMessage ?? '網路連線失敗'],
        syncedAt: DateTime.now(),
      );
    }

    try {
      await _syncMessages(fetchResult.messages);
      return SyncResult(
        success: true,
        messagesSynced: true,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        success: false,
        errors: ['留言同步失敗: $e'],
        syncedAt: DateTime.now(),
      );
    }
  }

  /// 新增留言並同步到雲端
  Future<ApiResult> addMessageAndSync(Message message) async {
    // 1. 先存到本地
    await _messageRepo.addMessage(message);

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

    // 2. 從雲端刪除
    final result = await _sheetsService.deleteMessage(uuid);

    if (!result.success) {
      // TODO: 實作離線佇列，稍後重試
    }

    return result;
  }

  /// 內部方法：雙向同步留言
  Future<void> _syncMessages(List<Message> cloudMessages) async {
    // 取得雲端留言的 UUID 集合
    final cloudUuids = cloudMessages.map((m) => m.uuid).toSet();

    // 1. 找出本地有但雲端沒有的留言 (待上傳)
    final pendingMessages = _messageRepo.getPendingMessages(cloudUuids);

    // 2. 上傳待同步的留言
    for (final msg in pendingMessages) {
      await _sheetsService.addMessage(msg);
    }

    // 3. 從雲端同步到本地 (會自動處理新增/刪除)
    await _messageRepo.syncFromCloud(cloudMessages);
  }
}

/// 同步結果
class SyncResult {
  final bool success;
  final bool itinerarySynced;
  final bool messagesSynced;
  final List<String> errors;
  final DateTime syncedAt;

  SyncResult({
    required this.success,
    this.itinerarySynced = false,
    this.messagesSynced = false,
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
