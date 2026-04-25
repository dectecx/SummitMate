import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../../data/models/trip.dart';

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
  ///
  /// [itinerarySynced] 是否同步了行程
  /// [messagesSynced] 是否同步了留言
  /// [pollsSynced] 是否同步了投票
  /// [syncedAt] 同步時間
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
  ///
  /// [message] 錯誤訊息
  /// [errors] 詳細錯誤列表
  factory SyncResult.failure(String message, {List<String>? errors}) {
    return SyncResult(isSuccess: false, errorMessage: message, errors: errors ?? [message], syncedAt: DateTime.now());
  }

  /// 建立跳過結果 (離線或節流)
  ///
  /// [reason] 跳過原因
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
  ///
  /// [isAuto] 是否為自動同步 (受節流限制)
  Future<SyncResult> syncAll({bool isAuto = false});

  /// 取得雲端行程列表
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({String? cursor, int? limit});

  /// 取得最後同步時間
  DateTime? get lastItinerarySync;
  DateTime? get lastMessagesSync;

  /// 重設同步時間 (用於測試)
  void resetLastSyncTimes();
}
