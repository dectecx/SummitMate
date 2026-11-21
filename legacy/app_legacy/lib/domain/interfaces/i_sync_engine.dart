import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../entities/trip.dart';
import '../enums/sync_status.dart';

/// 同步結果
class SyncResult {
  final bool isSuccess;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final int idMigrationsCount;
  final List<String> errors;
  final String? errorMessage;
  final DateTime syncedAt;

  const SyncResult({
    required this.isSuccess,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.idMigrationsCount = 0,
    this.errors = const [],
    this.errorMessage,
    required this.syncedAt,
  });

  /// 建立成功結果
  factory SyncResult.success({
    int pushedCount = 0,
    int pulledCount = 0,
    int conflictCount = 0,
    int idMigrationsCount = 0,
    DateTime? syncedAt,
  }) {
    return SyncResult(
      isSuccess: true,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      conflictCount: conflictCount,
      idMigrationsCount: idMigrationsCount,
      syncedAt: syncedAt ?? DateTime.now(),
    );
  }

  /// 建立失敗結果
  factory SyncResult.failure(String message, {List<String>? errors}) {
    return SyncResult(isSuccess: false, errorMessage: message, errors: errors ?? [message], syncedAt: DateTime.now());
  }

  @override
  String toString() {
    if (isSuccess) {
      return '同步成功 (pushed: $pushedCount, pulled: $pulledCount, '
          'conflicts: $conflictCount, idMigrations: $idMigrationsCount)';
    } else {
      return '同步失敗: ${errors.join(', ')}';
    }
  }
}

/// 同步方向
enum SyncDirection {
  /// 上傳 (本地覆蓋雲端)
  upload,

  /// 下載 (雲端覆蓋本地)
  download,
}

/// 同步引擎介面
///
/// 負責編排本地待同步資料的上傳 (Push) 與遠端資料的拉取合併 (Pull)。
/// 取代舊的 ISyncService，職責更清晰：
/// - Push: 查詢所有 syncStatus != synced 的本地記錄 → 呼叫 SyncAdapter → 標記 synced
/// - Pull: 呼叫 SyncAdapter → 以 updatedAt LWW 合併
/// - 定時輪詢: 依使用者設定的間隔自動觸發 runSyncCycle
abstract interface class ISyncEngine {
  /// 執行完整同步週期 (Push pending → Pull remote → Merge)
  Future<SyncResult> runSyncCycle();

  /// 針對單一行程執行有向同步
  ///
  /// [tripId] 指定行程的 ID；[direction] 為 upload（本地推雲端）或 download（雲端拉本地）。
  /// 僅同步隸屬該行程的資料（行程本體、行程節點、裝備），不影響其他行程或使用者層級資料。
  Future<SyncResult> syncTrip(String tripId, SyncDirection direction);

  /// 僅推送本地待同步資料到遠端
  Future<SyncResult> pushPending();

  /// 僅拉取遠端資料並與本地合併
  Future<SyncResult> pullRemote();

  /// 取得雲端行程列表
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({int? page, int? limit});

  /// 手動上傳行程至雲端
  Future<Result<String, Exception>> uploadToCloud(Trip trip);

  /// 手動從雲端刪除行程
  Future<Result<void, Exception>> removeFromCloud(String tripId);

  /// 監看待同步項目總數
  Stream<int> watchPendingSyncCount();

  /// 監看特定表的同步狀態
  Stream<SyncStatus> watchSyncStatus(String table);

  /// 重設同步時間
  void resetLastSyncTimes();

  /// 取得最後同步時間
  Future<DateTime?> getLastSyncTime();

  /// 啟動/重啟定時同步 (當使用者變更設定時呼叫)
  void reconfigureAutoSync();

  /// 停止定時同步
  void stopAutoSync();

  /// 釋放資源
  void dispose();
}
