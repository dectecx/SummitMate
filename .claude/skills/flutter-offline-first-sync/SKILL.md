---
name: flutter-offline-first-sync
description: Standardizes SummitMate's Flutter data-access architecture (the "three sync modes"). Use when adding or changing how a feature reads/writes data, deciding whether an operation is online-only / cached-read+online-write / offline-first, adding a Repository, or adding/adjusting an ISyncAdapter for background sync.
---

# Skill: Flutter 資料存取架構（三模式同步）

## 核心原則（最重要，先讀這段）

> **每個功能的資料存取，UI／Cubit 一律只呼叫該功能的 `Repository`。**
> `Repository` 是該功能的唯一資料 API；「遠端」是它的實作細節。
> Cubit 不判斷連線、不在 `repository` 與其他資料物件之間二選一。

- 沒有 `CloudService` 之類的平行資料層。需要線上能力時，由 Repository 自己（受控地）呼叫 `RemoteDataSource`。
- 連線判斷、離線錯誤、快取更新都收斂在 Repository（透過共用 helper），UI 只負責顯示結果或錯誤 Toast。

## 三種同步模式

每個**操作**（不是每個功能）屬於下列其一；同一個 Repository 可混用多種模式。

| 模式 | 讀取 | 寫入 | 遠端放哪 | 典型功能 |
| --- | --- | --- | --- | --- |
| **A. OnlineOnly**（純線上） | 直接打遠端，離線→`OfflineException` | 直接打遠端 | Repository 內呼叫 RemoteDataSource，經 `online()` 守門 | 成員搜尋／管理、雲端裝備庫瀏覽、手動雲端行程操作 |
| **B. CachedRead + OnlineWrite**（讀快取／寫線上） | 先回本地快取（線上時可背景 `refresh()`） | 直接打遠端，成功後更新本地快取 | 同上 | 投票、留言、揪團 create/update/delete 與社交互動 |
| **C. OfflineFirst**（離線可寫，pending） | 本地 | 寫本地 + 標 `syncStatus=pending*`，**不阻塞網路** | 由 `SyncEngine` 透過該功能的 `ISyncAdapter` 背景 push/pull | 行程本體、行程節點、裝備、最愛 |

### 「遠端放哪」的單一準則
- **C 模式**：Repository **永不**在前景打網路。實際遠端推拉交給 `SyncEngine` + `XxxSyncAdapter`。
- **A／B 模式**：Repository 直接呼叫 `RemoteDataSource`，但**一律經過 `RepositoryRemoteAccess` 守門 helper**。

## A／B 模式：`RepositoryRemoteAccess`

位置：`app/lib/data/repositories/base/repository_remote_access.dart`

```dart
class PollRepository implements IPollRepository with RepositoryRemoteAccess {
  final IPollLocalDataSource _local;
  final IPollRemoteDataSource _remote;
  @override
  final IConnectivityService connectivity; // helper 需要

  // B 模式讀：本地快取
  Future<List<Poll>> getByTripId(String tripId) =>
      cachedRead(() => _local.getByTripId(tripId));

  // B 模式寫：線上限定 + 成功後更新快取
  Future<Result<String, Exception>> create(...) =>
      online('createPoll', () => _remote.createPoll(...));
}
```

- `online(op, request, {cache})`：離線直接回 `OfflineException`；線上才送出；成功且給 `cache` 時更新本地。
- `cachedRead(local, {refresh})`：先回本地；線上且有 `refresh` 時在背景刷新（不阻塞）。

## C 模式：可同步實體 + Adapter + 引擎

### 1. 實體實作 `SyncableEntity`
`app/lib/domain/interfaces/i_syncable_entity.dart`：實體需提供 `id` / `syncStatus` / `updatedAt`（freezed 直接 `implements SyncableEntity`）。

### 2. `ISyncAdapter`（每個 C 模式功能一個）
`app/lib/domain/interfaces/i_sync_adapter.dart`：
```dart
abstract interface class ISyncAdapter {
  String get tableName;                 // Drift 表名（待同步計數／markAsSynced）
  Future<SyncPushResult> pushPending(); // 推送本地 pending
  Future<SyncMergeResult> pullRemote(); // 拉取並 LWW 合併
}
```

### 3. 繼承 `BaseSyncAdapter<T>`（強烈建議）
`app/lib/infrastructure/services/adapters/base_sync_adapter.dart` 已把「push 迴圈 + ID 遷移 transaction + markSynced/markError + 遠端刪除偵測 + LWW 合併」通用化。子類只填 hook：
- Push：`getLocalItems()`、`pushOne(item)`（依 `syncStatus` 呼叫遠端；刪除時自行刪本地；建立回傳 `IdMigration?`）、`migrateLocalId()`
- Pull：`resolveScopes()`（如每個本地 tripId）、`fetchRemote(scope)`、`getLocalItemsForScope(scope)`、`getLocalById()`、`upsertLocalSynced(remote, local)`、`markLocalConflict()`、`deleteLocal()`
- 可選覆寫：`wasEverSynced()`（預設 `!= pendingCreate`；Trip 用 `cloudSyncedAt != null`）、`timestampOf()`（LWW 比較時間）

### 4. 註冊到引擎（不需改 `SyncEngine`）
在 `app/lib/core/di/sync_module.dart` 的清單加入 adapter。**清單順序即同步優先級**（父領域先於子領域）：
```dart
List<ISyncAdapter> syncAdapters(TripSyncAdapter t, ItinerarySyncAdapter i, GearSyncAdapter g, /* NewAdapter n */)
    => [t, i, g, /* n */];
```
`SyncEngine`（`infrastructure/services/sync_engine.dart`）只編排 `List<ISyncAdapter>`，不認識任何領域；新增領域零修改引擎。

### 5. UUID v7
本地新建資料用 UUID v7 當臨時主鍵；推送成功後若後端配發永久 ID，`pushOne` 回傳 `IdMigration`，由 base 在 transaction 內遷移。

## 如何選模式（決策樹）
1. 離線時完全不能用（需即時後端狀態）？→ **A**。
2. 離線可看舊資料，但寫入必須連線（投票、留言、社交）？→ **B**。
3. 離線要能新增/編輯並於連線後自動同步？→ **C**。
- 同一功能可混用：例如多數寫入走 C，但某個特定操作必須即時 → 該操作走 A/B。

## Verification
- **UI/Cubit 只依賴 Repository**：不得直接注入 `RemoteDataSource`、`SyncEngine`（同步觸發 UI 例外）或任何平行資料服務。
- **A/B**：所有遠端呼叫都經 `online()`；離線時回 `OfflineException` 而非丟例外或靜默失敗。
- **C**：Repository 寫入只動本地 + `syncStatus`，**不**在前景打網路；遠端在 adapter。
- **新 C 模式功能**：實體 `implements SyncableEntity`、adapter 繼承 `BaseSyncAdapter`、已加入 `SyncModule` 清單且順序正確。
- 執行 `dart run build_runner build --delete-conflicting-outputs` 後 `flutter analyze` 與相關測試需綠燈。

## 相關檔案
| 用途 | 檔案 |
| --- | --- |
| A/B 守門 helper | `app/lib/data/repositories/base/repository_remote_access.dart` |
| 可同步實體介面 | `app/lib/domain/interfaces/i_syncable_entity.dart` |
| Adapter 介面/結果型別 | `app/lib/domain/interfaces/i_sync_adapter.dart` |
| Adapter 共用基底 | `app/lib/infrastructure/services/adapters/base_sync_adapter.dart` |
| 通用同步引擎 | `app/lib/infrastructure/services/sync_engine.dart` |
| Adapter 註冊 | `app/lib/core/di/sync_module.dart` |
| 衝突解決（LWW） | `app/lib/infrastructure/services/sync_conflict_resolver.dart` |
| 離線判斷 | `app/lib/infrastructure/services/connectivity_service.dart` |
