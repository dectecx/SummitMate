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
  // === 同步相關 ===
  // ============================================================

  /// 自動同步節流間隔 (分鐘)
  /// 避免頻繁觸發自動同步
  static const int syncThrottleMinutes = 5;

  /// 自動同步節流間隔 Duration
  static const Duration syncThrottleDuration = Duration(minutes: syncThrottleMinutes);

  // ============================================================
  // === Token 相關 ===
  // ============================================================

  /// Token 即將過期警告時間 (分鐘)
  /// 當 Token 剩餘時間低於此值時，嘗試刷新
  static const int tokenExpiryWarningMinutes = 5;

  /// Token 即將過期警告 Duration
  static const Duration tokenExpiryWarning = Duration(minutes: tokenExpiryWarningMinutes);
}
