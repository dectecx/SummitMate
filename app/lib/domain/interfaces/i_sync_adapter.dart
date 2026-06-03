import '../../core/error/result.dart';
import '../enums/sync_status.dart';

/// 同步適配器介面
///
/// 每個 T1 (離線雙向同步) 資料類型實作一個，供 SyncEngine 調用。
/// 封裝了 push (本地 → 遠端) 和 pull (遠端 → 本地) 的具體邏輯。
abstract interface class ISyncAdapter<T> {
  /// 將本地待同步項目推送到遠端
  ///
  /// [item] 要推送的本地項目
  /// [status] 項目的 syncStatus (pendingCreate / pendingUpdate / pendingDelete)
  ///
  /// 回傳 [IdMigration] 若後端回傳了新的永久 ID (通常在 pendingCreate 時)，
  /// 回傳 null 若不需要 ID 遷移。
  Future<Result<IdMigration?, Exception>> pushItem(T item, SyncStatus status);

  /// 從遠端拉取資料並與本地合併 (LWW)
  ///
  /// [scopeId] 同步範圍 ID (通常為 tripId 或 userId)
  ///
  /// 回傳合併結果統計。
  Future<Result<SyncMergeResult, Exception>> pullAndMerge(String scopeId);
}

/// ID 遷移結果
///
/// 當前端使用臨時 UUID 建立資料，上傳成功後後端回傳永久 ID，
/// SyncEngine 需呼叫 Repository 的 updateLocalId() 進行遷移。
class IdMigration {
  /// 前端臨時 ID
  final String tempId;

  /// 後端永久 ID
  final String permanentId;

  const IdMigration({required this.tempId, required this.permanentId});

  @override
  String toString() => 'IdMigration($tempId → $permanentId)';
}

/// 合併結果統計
class SyncMergeResult {
  /// 從遠端拉取的項目數
  final int pulledCount;

  /// 發生衝突的項目數
  final int conflictCount;

  /// 本地勝出 (本地較新) 的項目數
  final int localWinsCount;

  /// 遠端勝出 (遠端較新) 的項目數
  final int remoteWinsCount;

  const SyncMergeResult({
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.localWinsCount = 0,
    this.remoteWinsCount = 0,
  });

  SyncMergeResult operator +(SyncMergeResult other) {
    return SyncMergeResult(
      pulledCount: pulledCount + other.pulledCount,
      conflictCount: conflictCount + other.conflictCount,
      localWinsCount: localWinsCount + other.localWinsCount,
      remoteWinsCount: remoteWinsCount + other.remoteWinsCount,
    );
  }

  @override
  String toString() =>
      'SyncMergeResult(pulled: $pulledCount, conflicts: $conflictCount, '
      'localWins: $localWinsCount, remoteWins: $remoteWinsCount)';
}
