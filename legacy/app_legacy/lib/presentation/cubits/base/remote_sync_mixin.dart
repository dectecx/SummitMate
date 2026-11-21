import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/error/app_error_handler.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/infrastructure/tools/log_service.dart';
import 'safe_emit_mixin.dart';
import 'toast_notification.dart';

/// 為需要遠端同步的 Cubit 提供統一的離線檢查、訪客限制、冷卻機制與
/// `isSyncing` 狀態管理。
///
/// 依賴 [SafeEmitMixin]，宿主 Cubit 必須同時混入兩者：
/// ```dart
/// class GroupEventCubit extends Cubit<GroupEventState>
///     with SafeEmitMixin<GroupEventState>, RemoteSyncMixin<GroupEventState> { ... }
/// ```
///
/// **宿主 Cubit 必須實作的抽象成員：**
/// - [connectivity] — 連線狀態服務
/// - [withSyncing] — 回傳設定 `isSyncing` 後的新 State
/// - [withNotification] — 回傳帶有 [ToastNotification] 的新 State
///
/// **宿主 Cubit 可選覆寫的成員：**
/// - [isGuest] — 是否為訪客（預設 false）
/// - [syncCooldown] — 自動同步冷卻時間（預設 [Duration.zero] = 停用）
/// - [syncLastTime] — 上次同步時間，供冷卻計算使用
mixin RemoteSyncMixin<S> on Cubit<S>, SafeEmitMixin<S> {
  // ──────────────────────────────────────────
  // Required abstract members
  // ──────────────────────────────────────────

  /// 連線狀態服務，由宿主 Cubit 提供。
  IConnectivityService get connectivity;

  /// 回傳將 [isSyncing] 設定到當前 State 後的新 State。
  ///
  /// 若當前 State 不適合設定 isSyncing（例如仍在 Loading），
  /// 可直接回傳原始 [current] 不作變更。
  S withSyncing(S current, bool isSyncing);

  /// 回傳將 [notification] 設定到當前 State 後的新 State。
  ///
  /// 若當前 State 不適合附加通知，可回傳原始 [current]。
  S withNotification(S current, ToastNotification notification);

  // ──────────────────────────────────────────
  // Optional overridable members
  // ──────────────────────────────────────────

  /// 是否為訪客使用者。預設為 false。
  bool get isGuest => false;

  /// 自動同步冷卻時間；設為 [Duration.zero] 代表停用冷卻機制。
  Duration get syncCooldown => Duration.zero;

  /// 上次成功同步的時間，供冷卻機制計算使用。
  DateTime? get syncLastTime => null;

  // ──────────────────────────────────────────
  // Utility properties
  // ──────────────────────────────────────────

  bool get isOffline => connectivity.isOffline;

  bool _isCoolingDown() {
    final cooldown = syncCooldown;
    if (cooldown == Duration.zero) return false;
    final last = syncLastTime;
    if (last == null) return false;
    return DateTime.now().difference(last) < cooldown;
  }

  // ──────────────────────────────────────────
  // State helpers
  // ──────────────────────────────────────────

  void _setIsSyncing(bool value) {
    final next = withSyncing(state, value);
    if (!identical(next, state)) safeEmit(next);
  }

  void _emitNotification(ToastNotification notification) {
    final next = withNotification(state, notification);
    if (!identical(next, state)) safeEmit(next);
  }

  // ──────────────────────────────────────────
  // Guard helpers
  // ──────────────────────────────────────────

  /// 若為訪客則發送 [guestMessage] 通知並回傳 true（代表「應中止」）。
  bool guardGuest(String guestMessage) {
    if (!isGuest) return false;
    _emitNotification(ToastNotification.warning(guestMessage));
    return true;
  }

  /// 若離線則根據 [isAuto] 決定是否發送 [offlineMessage] 通知，回傳 true 代表應中止。
  bool guardOffline(String offlineMessage, {bool isAuto = false}) {
    if (!isOffline) return false;
    if (!isAuto) _emitNotification(ToastNotification.error(offlineMessage));
    return true;
  }

  // ──────────────────────────────────────────
  // Core guarded action runner
  // ──────────────────────────────────────────

  /// 以統一流程執行遠端操作：
  /// 1. 訪客檢查（可選）→ 離線檢查 → 冷卻檢查（可選）
  /// 2. 設定 `isSyncing = true`
  /// 3. 執行 [action]
  /// 4. 成功：發送 [onSuccessNotification]（若非 auto 且不為 null）
  /// 5. 失敗：發送 [onErrorNotification]（若非 auto）；恢復 `isSyncing = false`
  ///
  /// 回傳值：
  /// - `true`  = action 成功完成
  /// - `false` = 被守門條件中止，或 action 拋出例外
  Future<bool> runWithSyncGuard({
    required Future<void> Function() action,
    required String offlineMessage,
    String? guestMessage,
    bool isAuto = false,
    bool useCooldown = false,
    ToastNotification? successNotification,
    ToastNotification Function(Object e)? buildErrorNotification,
    String? logSource,
  }) async {
    if (guestMessage != null && guardGuest(guestMessage)) return false;
    if (guardOffline(offlineMessage, isAuto: isAuto)) return false;
    if (useCooldown && isAuto && _isCoolingDown()) return false;

    _setIsSyncing(true);
    try {
      await action();
      if (successNotification != null && !isAuto) {
        _emitNotification(successNotification);
      }
      return true;
    } catch (e) {
      final src = logSource ?? 'RemoteSyncMixin';
      LogService.error('Sync action failed: $e', source: src);
      if (!isAuto) {
        final notification = buildErrorNotification != null
            ? buildErrorNotification(e)
            : ToastNotification.error(AppErrorHandler.getUserMessage(e));
        _emitNotification(notification);
      }
      _setIsSyncing(false);
      return false;
    }
  }
}
