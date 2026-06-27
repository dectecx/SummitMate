import 'dart:async';
import '../../../core/error/result.dart';
import '../../../core/exceptions/offline_exception.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';

/// Repository 三模式存取的共用守門 helper。
///
/// 依 SummitMate 的資料存取架構，每個 Repository 是其功能的唯一資料 API，
/// 而「遠端」是它的實作細節。各操作依其同步模式選用對應方法：
///
/// - **A. OnlineOnly（純線上）**：讀寫皆需連線。使用 [online]。
/// - **B. CachedRead + OnlineWrite（讀快取／寫線上）**：讀走本地、寫走 [online]
///   並於成功後更新快取（`cache` 參數）；可用 [cachedRead] 在回傳本地後背景刷新。
/// - **C. OfflineFirst（離線可寫，pending）**：不經過本 mixin，改由寫本地 +
///   標記 `syncStatus`，遠端推拉交給 `SyncEngine` 與該功能的 `ISyncAdapter`。
///
/// 宿主 Repository 只需提供 [connectivity]。
mixin RepositoryRemoteAccess {
  /// 連線狀態服務，由宿主 Repository 提供。
  IConnectivityService get connectivity;

  bool get isOffline => connectivity.isOffline;

  /// 線上限定操作（A／B 模式的寫入與遠端拉取）。
  ///
  /// 離線時直接回傳 [OfflineException]，不會發出任何網路請求。
  /// 成功時若提供 [cache]，會以遠端回傳值更新本地快取。
  ///
  /// [operation] 操作名稱（供錯誤訊息與除錯）。
  /// [request] 實際的遠端請求。
  /// [cache] 可選；成功後以結果值更新本地快取。
  Future<Result<T, Exception>> online<T>(
    String operation,
    Future<Result<T, Exception>> Function() request, {
    Future<void> Function(T value)? cache,
  }) async {
    if (isOffline) {
      return Failure(OfflineException('離線模式無法執行此操作', operationName: operation));
    }
    try {
      final result = await request();
      if (result is Success<T, Exception> && cache != null) {
        await cache(result.value);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 讀快取 + 背景刷新（B 模式的讀取）。
  ///
  /// 立即回傳本地快取 [local]；若在線上且提供 [refresh]，則在背景觸發一次刷新
  /// （不等待、不阻塞回傳），刷新負責更新本地資料。
  Future<List<T>> cachedRead<T>(
    Future<List<T>> Function() local, {
    Future<void> Function()? refresh,
  }) async {
    final data = await local();
    if (refresh != null && !isOffline) {
      unawaited(refresh());
    }
    return data;
  }
}
