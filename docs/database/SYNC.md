# 同步機制 (Sync Mechanism)

SummitMate 採用 **Offline-First** 策略，所有操作優先寫入本地 Hive，再背景同步至雲端。

---

## 同步流程

```mermaid
sequenceDiagram
    participant App
    participant SyncService
    participant Hive as Local (Hive)
    participant GAS as Remote (GAS)

    App->>SyncService: syncAll()

    Note over SyncService: Phase 1: Push
    SyncService->>Hive: getPending()
    Hive-->>SyncService: pendingItems

    loop Each Item
        SyncService->>GAS: push(item)
        GAS-->>SyncService: ok
        SyncService->>Hive: markSynced(item)
    end

    Note over SyncService: Phase 2: Pull
    SyncService->>GAS: fetchLatest(since)
    GAS-->>SyncService: remoteItems
    SyncService->>Hive: upsert(items)

    SyncService-->>App: SyncResult
```

---

## SyncStatus 狀態機

```mermaid
stateDiagram-v2
    [*] --> pendingCreate: 本地新增
    [*] --> synced: 從雲端下載

    pendingCreate --> synced: push成功
    pendingCreate --> error: push失敗

    synced --> pendingUpdate: 本地修改
    synced --> pendingDelete: 本地刪除

    pendingUpdate --> synced: push成功
    pendingDelete --> [*]: push成功

    error --> pendingCreate: 重試
    error --> pendingUpdate: 重試
```

---

## 同步策略

| 情境     | 策略                    |
| :------- | :---------------------- |
| 線上     | 先讀 cache，背景 fetch  |
| 離線     | 只讀 Hive，禁止寫入雲端 |
| 恢復連線 | 自動同步 (5分鐘節流)    |

---

## 衝突解決

採用 **Last-Write-Wins** 策略：

- 比較 `updatedAt` 時間戳
- 較新的資料覆蓋舊資料
- 若時間相同，以雲端為準

---

## 相關檔案

| 功能     | 檔案                                                |
| :------- | :-------------------------------------------------- |
| 同步服務 | `infrastructure/services/sync_service.dart`         |
| 連線判斷 | `infrastructure/services/connectivity_service.dart` |
| 離線配置 | `core/offline_config.dart`                          |
