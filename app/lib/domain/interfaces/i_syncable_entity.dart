import '../enums/sync_status.dart';

/// 可同步實體介面
///
/// C 模式（OfflineFirst，離線可寫 pending）的領域實體需實作此介面，
/// 供 `BaseSyncAdapter` 以統一流程進行推送、ID 遷移與 LWW 衝突合併。
abstract interface class SyncableEntity {
  /// 主鍵（本地新建時為 UUID v7 臨時 ID，推送後可能遷移為永久 ID）。
  String get id;

  /// 同步狀態。
  SyncStatus get syncStatus;

  /// 最後更新時間，供 Last-Write-Wins 衝突解決比較。
  DateTime? get updatedAt;
}
