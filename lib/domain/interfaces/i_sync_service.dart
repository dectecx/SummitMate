import 'i_data_service.dart';
import '../../data/models/message.dart';

/// 同步結果
class SyncResult {
  final bool isSuccess;
  final bool itinerarySynced;
  final bool messagesSynced;
  final bool pollsSynced;
  final List<String> errors;
  final String? errorMessage;
  final DateTime syncedAt;
  final String? skipReason;

  const SyncResult({
    required this.isSuccess,
    this.itinerarySynced = false,
    this.messagesSynced = false,
    this.pollsSynced = false,
    this.errors = const [],
    this.errorMessage,
    required this.syncedAt,
    this.skipReason,
  });

  /// 建立成功結果
  factory SyncResult.success({
    bool itinerarySynced = true,
    bool messagesSynced = true,
    bool pollsSynced = false,
    DateTime? syncedAt,
  }) {
    return SyncResult(
      isSuccess: true,
      itinerarySynced: itinerarySynced,
      messagesSynced: messagesSynced,
      pollsSynced: pollsSynced,
      syncedAt: syncedAt ?? DateTime.now(),
    );
  }

  /// 建立失敗結果
  factory SyncResult.failure(String message, {List<String>? errors}) {
    return SyncResult(isSuccess: false, errorMessage: message, errors: errors ?? [message], syncedAt: DateTime.now());
  }

  /// 建立跳過結果 (離線或節流)
  factory SyncResult.skipped({required String reason}) {
    return SyncResult(isSuccess: true, skipReason: reason, syncedAt: DateTime.now());
  }

  @override
  String toString() {
    if (isSuccess) {
      return '同步成功 (${syncedAt.toIso8601String()})';
    } else {
      return '同步失敗: ${errors.join(', ')}';
    }
  }
}

/// 資料同步服務介面
/// 負責本地與雲端資料的雙向同步
abstract interface class ISyncService {
  /// 完整同步 (行程 + 留言)
  /// [isAuto] 是否為自動同步 (受節流限制)
  Future<SyncResult> syncAll({bool isAuto = false});

  /// 僅同步行程資料
  Future<SyncResult> syncItinerary({bool isAuto = false});

  /// 僅同步留言資料
  Future<SyncResult> syncMessages({bool isAuto = false});

  /// 上傳本地待同步的留言
  Future<SyncResult> uploadPendingMessages();

  /// 上傳行程資料
  Future<SyncResult> uploadItinerary();

  /// 檢查行程是否有衝突
  Future<bool> checkItineraryConflict();

  /// 取得雲端行程列表
  Future<GetTripsResult> getCloudTrips();

  /// 取得最後同步時間
  DateTime? get lastItinerarySync;
  DateTime? get lastMessagesSync;

  /// 新增留言並同步到雲端
  Future<ApiResult> addMessageAndSync(Message message);

  /// 刪除留言並同步到雲端
  Future<ApiResult> deleteMessageAndSync(String uuid);

  /// 重設同步時間 (用於測試)
  void resetLastSyncTimes();
}
