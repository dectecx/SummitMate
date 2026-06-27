/// 同步適配器介面（C 模式：OfflineFirst）
///
/// 每個離線可寫（pending）的資料類型實作一個，供 `SyncEngine` 統一編排。
/// 引擎本身不認識任何領域；領域細節（遠端呼叫、scope 解析、欄位保留）
/// 全部收斂在各 adapter（通常透過 `BaseSyncAdapter` 共用流程）。
abstract interface class ISyncAdapter {
  /// 對應的 Drift 資料表名稱（供待同步計數與 `markAsSynced`／`markAsError`）。
  String get tableName;

  /// 推送本地所有待同步項目（`syncStatus != synced`）到遠端。
  ///
  /// 負責讀取 pending、依狀態 push、處理 ID 遷移與標記 synced/error，
  /// 並回傳本次推送統計（含錯誤訊息）。
  Future<SyncPushResult> pushPending();

  /// 從遠端拉取並以 Last-Write-Wins 合併到本地。
  ///
  /// 負責解析同步範圍（scope）、拉取遠端、偵測遠端刪除與衝突合併，
  /// 並回傳本次合併統計（含錯誤訊息）。
  Future<SyncMergeResult> pullRemote();
}

/// ID 遷移結果
///
/// 當前端使用臨時 UUID 建立資料，上傳成功後後端回傳永久 ID，
/// 需呼叫本地資料來源進行 ID 遷移。
class IdMigration {
  /// 前端臨時 ID
  final String tempId;

  /// 後端永久 ID
  final String permanentId;

  const IdMigration({required this.tempId, required this.permanentId});

  @override
  String toString() => 'IdMigration($tempId → $permanentId)';
}

/// 推送結果統計
class SyncPushResult {
  /// 成功推送的項目數
  final int pushedCount;

  /// 發生 ID 遷移的項目數
  final int idMigrationsCount;

  /// 推送過程中累積的錯誤訊息
  final List<String> errors;

  const SyncPushResult({this.pushedCount = 0, this.idMigrationsCount = 0, this.errors = const []});

  bool get isSuccess => errors.isEmpty;

  SyncPushResult operator +(SyncPushResult other) {
    return SyncPushResult(
      pushedCount: pushedCount + other.pushedCount,
      idMigrationsCount: idMigrationsCount + other.idMigrationsCount,
      errors: [...errors, ...other.errors],
    );
  }

  @override
  String toString() => 'SyncPushResult(pushed: $pushedCount, idMigrations: $idMigrationsCount, errors: ${errors.length})';
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

  /// 拉取過程中累積的錯誤訊息
  final List<String> errors;

  const SyncMergeResult({
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.localWinsCount = 0,
    this.remoteWinsCount = 0,
    this.errors = const [],
  });

  bool get isSuccess => errors.isEmpty;

  SyncMergeResult operator +(SyncMergeResult other) {
    return SyncMergeResult(
      pulledCount: pulledCount + other.pulledCount,
      conflictCount: conflictCount + other.conflictCount,
      localWinsCount: localWinsCount + other.localWinsCount,
      remoteWinsCount: remoteWinsCount + other.remoteWinsCount,
      errors: [...errors, ...other.errors],
    );
  }

  @override
  String toString() =>
      'SyncMergeResult(pulled: $pulledCount, conflicts: $conflictCount, '
      'localWins: $localWinsCount, remoteWins: $remoteWinsCount, errors: ${errors.length})';
}
