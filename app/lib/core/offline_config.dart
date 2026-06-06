/// 離線模式配置常數
///
/// 集中管理所有與離線功能相關的常數，便於統一調整
library;

class OfflineConfig {
  OfflineConfig._();

  // ============================================================
  // === 離線登入相關 ===
  // ============================================================

  /// 離線登入寬限期 (天)
  /// 當網路不可用時，若 Token 在此天數內仍視為有效
  static const int offlineGracePeriodDays = 7;

  /// 離線登入寬限期 Duration
  static const Duration offlineGracePeriod = Duration(days: offlineGracePeriodDays);

  // ============================================================
  // === 自動同步間隔相關 ===
  // ============================================================

  /// 自動同步最小間隔 (分鐘) — 使用者可設定的下限
  static const int autoSyncMinIntervalMinutes = 5;

  /// 自動同步最大間隔 (分鐘) — 使用者可設定的上限 (7天 = 10080 分鐘)
  static const int autoSyncMaxIntervalMinutes = 10080;

  /// DevTools 模式下的最小間隔 (分鐘) — 方便測試
  static const int autoSyncDevMinIntervalMinutes = 1;

  /// 自動同步預設間隔 (分鐘)
  static const int autoSyncDefaultIntervalMinutes = 5;

  // ============================================================
  // === Push 重試相關 ===
  // ============================================================

  /// Push 重試次數上限
  static const int maxPushRetryCount = 3;

  /// Push 失敗後的退避基礎時間 (秒)
  static const int pushRetryBackoffSeconds = 5;

  // ============================================================
  // === 合併策略相關 ===
  // ============================================================

  /// Pull 合併策略 (LWW = Last-Writer-Wins)
  static const String mergeStrategy = 'lww';

  /// LWW 衝突容忍時間閾值 (秒)
  ///
  /// 當本地與遠端的 `updatedAt` 時間差在此閾值以內時，視為本地勝出。
  /// 這是為了容忍不同裝置之間的系統時鐘誤差，避免秒級差距導致使用者修改被意外覆蓋。
  static const int conflictToleranceSeconds = 5;

  /// 自動 Push 延遲 (寫入後等待幾秒再 Push，避免頻繁操作)
  static const int autoPushDelaySeconds = 3;

  // ============================================================
  // === Token 相關 ===
  // ============================================================

  /// Token 即將過期警告時間 (分鐘)
  /// 當 Token 剩餘時間低於此值時，嘗試刷新
  static const int tokenExpiryWarningMinutes = 5;

  /// Token 即將過期警告 Duration
  static const Duration tokenExpiryWarning = Duration(minutes: tokenExpiryWarningMinutes);

  // ============================================================
  // === Helpers ===
  // ============================================================

  /// 驗證自動同步間隔是否在允許範圍內
  ///
  /// [minutes] 使用者設定的間隔分鐘數 (0 = 關閉)
  /// [isDevMode] 是否為 DevTools 模式 (可無視最小間隔限制)
  ///
  /// 回傳 clamped 後的合法值
  static int clampAutoSyncInterval(int minutes, {bool isDevMode = false}) {
    if (minutes == 0) return 0; // 0 = 關閉自動同步
    final min = isDevMode ? autoSyncDevMinIntervalMinutes : autoSyncMinIntervalMinutes;
    return minutes.clamp(min, autoSyncMaxIntervalMinutes);
  }
}
