import '../../../domain/enums/sync_status.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../domain/interfaces/i_syncable_entity.dart';
import '../../database/app_database.dart';
import '../sync_conflict_resolver.dart';

/// C 模式（OfflineFirst）同步適配器的共用基底。
///
/// 集中實作所有領域共通的：
/// - **Push**：讀 pending → 依狀態推送 → ID 遷移 → `markAsSynced`
///   （刪除排在最後、ID 遷移與標記在同一 transaction）。失敗的項目維持原本的
///   pending 狀態，錯誤只回報在 [SyncPushResult.errors]，下一輪自動重試。
/// - **Pull**：解析 scope → 拉取遠端 → 偵測遠端刪除 → Last-Write-Wins 合併。
///
/// 子類只需實作領域相關的 hook（遠端呼叫、本地讀寫、scope 解析、欄位保留）。
abstract class BaseSyncAdapter<T extends SyncableEntity> implements ISyncAdapter {
  /// 本地資料庫，供通用的 `markAsSynced` 與 ID 遷移 transaction。
  AppDatabase get db;

  /// 繼承 Base 的 adapter 都以 `syncStatus` 管理 pending，資料表必有 `sync_status` 欄位。
  @override
  bool get tracksSyncStatus => true;

  // ──────────────────────────────────────────
  // Push hooks
  // ──────────────────────────────────────────

  /// 取得本地所有項目（base 會自行過濾出 `syncStatus != synced`）。
  Future<List<T>> getLocalItems();

  /// 依 [item] 的 `syncStatus` 執行對應遠端操作。
  ///
  /// - 建立成功且後端回傳新 ID 時，回傳 [IdMigration]；否則回傳 null。
  /// - 刪除成功時，本 hook 需自行刪除本地資料。
  /// - 失敗時直接拋出例外，由 base 捕捉並標記 error。
  Future<IdMigration?> pushOne(T item);

  /// 將本地臨時 ID 遷移為後端永久 ID。
  Future<void> migrateLocalId(String oldId, String newId);

  // ──────────────────────────────────────────
  // Pull hooks
  // ──────────────────────────────────────────

  /// 解析需要拉取的 scope 清單（如 `[userId]` 或所有本地 tripId）。
  Future<List<String>> resolveScopes();

  /// 拉取指定 scope 的遠端項目。
  Future<List<T>> fetchRemote(String scope);

  /// 取得屬於指定 scope 的本地項目（供偵測遠端刪除）。
  Future<List<T>> getLocalItemsForScope(String scope);

  /// 透過 ID 取得本地項目。
  Future<T?> getLocalById(String id);

  /// 以遠端資料寫入本地並標記為 synced。
  ///
  /// [local] 為 null 代表本地尚無此筆（新增）；否則為更新，
  /// 子類可於此保留本地獨有欄位（如 Trip 的 `isActive`）。
  Future<void> upsertLocalSynced(T remote, T? local);

  /// 將本地項目標記為 conflict（本地勝出，等待下次推送）。
  Future<void> markLocalConflict(T local);

  /// 刪除本地項目。
  Future<void> deleteLocal(String id);

  /// 本地項目是否「曾被成功推送過」，供遠端刪除偵測。
  ///
  /// 預設：非 `pendingCreate` 即視為曾同步。
  bool wasEverSynced(T local) => local.syncStatus != SyncStatus.pendingCreate;

  /// 取得用於 LWW 比較的時間戳。預設使用 [SyncableEntity.updatedAt]。
  DateTime? timestampOf(T item) => item.updatedAt;

  // ──────────────────────────────────────────
  // ISyncAdapter — generic implementations
  // ──────────────────────────────────────────

  @override
  Future<SyncPushResult> pushPending() async {
    List<T> pending;
    try {
      pending = (await getLocalItems()).where((i) => i.syncStatus != SyncStatus.synced).toList();
    } catch (e) {
      return SyncPushResult(errors: ['讀取 $tableName 待同步項目失敗: $e']);
    }
    _sortPendingForPush(pending);
    return executePush(pending);
  }

  /// 預設實作：推送所有 pending（等同 [pushPending]）。
  ///
  /// 具 tripId 欄位的 adapter（如 [ItinerarySyncAdapter]、[GearSyncAdapter]）
  /// 應覆寫此方法以僅推送屬於 [tripId] 的項目。
  @override
  Future<SyncPushResult> pushPendingForTrip(String tripId) => pushPending();

  @override
  Future<SyncMergeResult> pullRemote() async {
    List<String> scopes;
    try {
      scopes = await resolveScopes();
    } catch (e) {
      return SyncMergeResult(errors: ['解析 $tableName 同步範圍失敗: $e']);
    }

    var merged = const SyncMergeResult();
    for (final scope in scopes) {
      try {
        merged = merged + await pullScope(scope);
      } catch (e) {
        merged = merged + SyncMergeResult(errors: ['拉取 $tableName ($scope) 失敗: $e']);
      }
    }
    return merged;
  }

  /// 預設實作：拉取所有 scope（等同 [pullRemote]）。
  ///
  /// 使用 tripId 作為 scope 的 adapter（如 [ItinerarySyncAdapter]、[GearSyncAdapter]）
  /// 應覆寫此方法以僅拉取 [tripId] 對應的遠端資料。
  @override
  Future<SyncMergeResult> pullRemoteForTrip(String tripId) => pullRemote();

  // ──────────────────────────────────────────
  // Protected helpers
  // ──────────────────────────────────────────

  /// 執行 push 迴圈，處理 ID 遷移與 synced/error 標記。
  ///
  /// 供 [pushPending] 與子類的 [pushPendingForTrip] 共用，避免重複邏輯。
  Future<SyncPushResult> executePush(List<T> pending) async {
    int pushed = 0;
    int migrations = 0;
    final errors = <String>[];

    for (final item in pending) {
      try {
        final migration = await pushOne(item);
        pushed++;
        if (migration != null) {
          await db.transaction(() async {
            await migrateLocalId(migration.tempId, migration.permanentId);
            await db.markAsSynced(tableName, migration.permanentId);
          });
          migrations++;
        } else if (item.syncStatus != SyncStatus.pendingDelete) {
          await db.markAsSynced(tableName, item.id);
        }
      } catch (e) {
        // 推送失敗時保留原本的 pending 狀態，下一輪同步會再次嘗試。
        // 若在此改成其他狀態，會丟失「待新增／更新／刪除」的意圖，進而造成資料遺失。
        errors.add('$tableName ${item.id} 推送失敗: $e');
      }
    }

    return SyncPushResult(pushedCount: pushed, idMigrationsCount: migrations, errors: errors);
  }

  /// 拉取單一 scope 並與本地合併（LWW）。
  ///
  /// 供 [pullRemote] 與子類的 [pullRemoteForTrip] 共用。
  Future<SyncMergeResult> pullScope(String scope) async {
    final remoteItems = await fetchRemote(scope);
    final remoteIds = remoteItems.map((e) => e.id).toSet();

    int pulled = remoteItems.length;
    int conflict = 0;
    int localWins = 0;
    int remoteWins = 0;

    // 偵測遠端刪除：本地存在但遠端已無此項目（且該項目曾被成功同步過）
    final localItems = await getLocalItemsForScope(scope);
    for (final local in localItems) {
      if (!remoteIds.contains(local.id) && wasEverSynced(local)) {
        await deleteLocal(local.id);
        if (SyncConflictResolver.hasPendingChanges(local.syncStatus)) {
          conflict++;
        } else {
          remoteWins++;
        }
      }
    }

    for (final remote in remoteItems) {
      final local = await getLocalById(remote.id);
      if (local == null) {
        await upsertLocalSynced(remote, null);
        remoteWins++;
      } else if (local.syncStatus == SyncStatus.synced) {
        await upsertLocalSynced(remote, local);
        remoteWins++;
      } else {
        conflict++;
        if (SyncConflictResolver.remoteIsNewer(timestampOf(local), timestampOf(remote))) {
          await upsertLocalSynced(remote, local);
          remoteWins++;
        } else {
          await markLocalConflict(local);
          localWins++;
        }
      }
    }

    return SyncMergeResult(
      pulledCount: pulled,
      conflictCount: conflict,
      localWinsCount: localWins,
      remoteWinsCount: remoteWins,
    );
  }

  // ──────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────

  void _sortPendingForPush(List<T> pending) {
    // 刪除排在最後，避免「先刪父再推子」造成的孤兒
    pending.sort((a, b) {
      final aDelete = a.syncStatus == SyncStatus.pendingDelete;
      final bDelete = b.syncStatus == SyncStatus.pendingDelete;
      if (aDelete && !bDelete) return 1;
      if (!aDelete && bDelete) return -1;
      return 0;
    });
  }
}
