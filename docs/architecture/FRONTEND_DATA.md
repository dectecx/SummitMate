# 前端資料層設計（Drift、Outbox、同步引擎）

> 2026-11-21 草案。搭配 `DATA_SYNC_AUTH.md`（伺服器端與同步協定）閱讀。
> 範圍：離線優先的資料（行程、成員、節點、裝備、餐食）、outbox、SyncEngine、Auth 狀態、帳號切換。

## 1. 重點結論

- 本地表與伺服器表**欄位一一對應**，只去掉稽核欄位，不加 `syncStatus`。
- **不使用 `drift_flutter` 之外的資料庫套件**。`sqlite3_flutter_libs 0.6.0+eol` 只是 `drift_flutter` 刻意保留的空殼（sqlite3 已改用 build hooks），不需處理。
- 同步用一個**描述表驅動的通用引擎**：每個實體一份欄位描述，引擎用它組 SQL、套用 patch、重疊本地待送修改。測試會驗證描述與 Drift 資料表欄位一致。
- 本地刪除是**硬刪除**加一筆 outbox 刪除操作；伺服器 tombstone 到達時也硬刪除。

## 2. 資料表

### 2.1 通則

| 項目 | 規則 |
| :-- | :-- |
| 主鍵 | `id TEXT`（UUID 字串，client 產生；成員 ID 依 `DATA_SYNC_AUTH.md` 的 v5 規則） |
| 欄位命名 | Drift 欄位使用 snake_case 名稱（`named('trip_id')`），與伺服器 JSON 完全相同，patch 可直接送出 |
| 時間戳 | `build.yaml` 設定 `store_date_time_values_as_text: true`，以 ISO 8601 文字儲存，不損失精度 |
| 純日期 | `start_date`、`end_date` 存 `YYYY-MM-DD` 文字，領域層轉成不含時區的日期，避免換時區日期位移 |
| 伺服器游標 | `sync_cursor` 存**伺服器回傳的原始字串**，不經過 `DateTime` 轉換，避免微秒被截斷 |
| 外鍵 | 開啟 `PRAGMA foreign_keys = ON`；子表對 `trips` 設 `ON DELETE CASCADE` |
| 個人資料 | `gear_items`、`meal_plan_days`、`meal_items` **不存 `user_id`**：伺服器只回傳本人的資料，本地全部都是「我的」 |

### 2.2 同步資料表

| 表 | 欄位（除 `id`） | 備註 |
| :-- | :-- | :-- |
| `trips` | `owner_id`（可空）、`name`、`description`、`start_date`、`end_date?`、`cover_image?`、`is_sample`（僅本地） | 訪客建立的行程 `owner_id` 為空；同步後由伺服器值覆蓋 |
| `trip_members` | `trip_id`、`user_id`、`role`、`display_name`、`avatar` | 唯讀快取，只由拉取寫入；client 邀請 / 移除時才送 outbox |
| `itinerary_items` | `trip_id`、`day_index`、`name`、`est_minutes?`、`altitude`、`distance`、`lat?`、`lng?`、`note`、`checked_in_at?` | |
| `gear_items` | `trip_id`、`name`、`weight`、`category`、`quantity`、`is_checked`、`sort_order` | |
| `meal_plan_days` | `trip_id`、`name`、`day_index` | |
| `meal_items` | `trip_id`、`meal_plan_day_id`、`meal_type`、`name`、`weight`、`calories`、`quantity`、`note` | 對 `meal_plan_days` 也設 CASCADE |

索引：各子表 `(trip_id)`，`outbox(entity, entity_id)`。

### 2.3 同步基礎設施表

**`outbox`**

| 欄位 | 說明 |
| :-- | :-- |
| `seq INTEGER PK AUTOINCREMENT` | 送出順序 |
| `op_id TEXT UNIQUE` | 冪等鍵，建立時產生；**合併後仍保留最初的 op_id** |
| `entity TEXT`、`entity_id TEXT` | |
| `type TEXT` | `upsert` / `delete` |
| `patch TEXT` | JSON，只含被修改的欄位（建立時含所有欄位與 `trip_id`） |
| `state TEXT` | `pending` / `failed` |
| `attempts INT`、`last_error TEXT?`、`created_at` | |

**`app_meta`**（單列，`id = 1`）：`account_id?`（本機資料屬於誰，訪客為空）、`sync_cursor?`、`last_synced_at?`、`email?`、`display_name?`、`avatar?`。

**`app_settings`**（key / value 文字）：主題、`welcome_seen`、`seen_hints`（JSON 陣列）等，取代 SharedPreferences。

### 2.4 刻意不放進資料庫的東西
- Token：`flutter_secure_storage`。
- 離線地圖：由 flutter_map_tile_caching 自己管理，下載任務的設計在地圖功能時另寫。
- 使用者搜尋結果、天氣、山岳資訊：在線讀取，不快取進同步表。

## 3. 寫入流程與 outbox 規則

所有寫入都經過一個 `OutboxWriter`，Repository 不直接碰 outbox 表：

```text
repository.updateItem(id, changes)
  └─ db.transaction {
       1. 更新本地資料列
       2. outbox.enqueueUpsert(entity, id, patch)
     }
  └─ syncEngine.requestSync()   // 去抖，已登入且有網路才會真正執行
```

### 3.1 合併規則（`enqueueUpsert` / `enqueueDelete`，同一交易內）

| 情境 | 動作 |
| :-- | :-- |
| 同一實體已有 pending 的 upsert | 把新 patch 合併進去（同名欄位後者覆蓋），保留原 `seq` 與 `op_id` |
| 已有 pending upsert，之後刪除，且該 upsert 是「建立」（伺服器還沒有） | 兩者都移除，不送出 |
| 已有 pending upsert（伺服器已有此列）後刪除 | 移除 upsert，改排一筆 delete |
| 刪除行程 | 移除該行程底下所有實體尚在 outbox 的操作，只排一筆行程 delete |
| 實體屬於 `is_sample` 行程 | **不進 outbox**（範例行程只存在本機） |

「是否為建立」以 outbox 內該筆 upsert 的 patch 是否含 `trip_id`（或為 trips 時含 `name` + `start_date`）判定，並在 `outbox` 另存 `is_create` 旗標，避免每次猜測。

### 3.2 失敗處理
- 網路錯誤、5xx、401：本輪停止，指數退避，操作保持 `pending`。
- `forbidden` / `invalid`：標記 `failed`，保留 `last_error`；**不阻擋後面的操作**。
- 使用者可在「同步失敗」畫面逐筆**重試**或**捨棄**。捨棄一筆「建立行程」時，連同本地行程與其所有 pending 子操作一併移除。

## 4. 拉取套用規則

每一頁在**一個交易**內，依 `trips → trip_members → itinerary_items → meal_plan_days → gear_items → meal_items` 的順序套用：

1. 若該實體在 outbox 有 pending 的 **delete** → 略過。
2. 有 `deleted_at` 的列 → 硬刪除本地列（CASCADE 帶走子資料）。收到**自己**的 `trip_members` tombstone → 刪除整個行程。
3. 其他列 → `INSERT ... ON CONFLICT(id) DO UPDATE`，之後**重新疊上** outbox 中該實體的 pending patch。
4. 父列不存在（例如子列比行程先到、或行程已被刪）→ 略過該列，不報錯。
5. 套用完成後，`sync_cursor` 設為 `next_since`，同一個交易內更新。

首次請求使用 `cursor - 5 秒`；翻頁時使用回傳的 `next_since`，不再減。

## 5. SyncEngine

單一實例、同一時間只有一輪，使用鎖避免重入。

```text
sync():
  未登入（訪客）或 NeedsReauth → 結束
  push:  依 seq 取 pending，每批 ≤ 50（伺服器上限 100）
         applied  → 刪除 outbox 項目；把回傳的完整列寫入本地（重疊其他 pending patch）
         gone     → 刪除 outbox 項目；刪除本地列
         forbidden/invalid → failed
         網路錯誤 → 停止本輪
  pull:  迴圈直到 has_more = false
  成功 → app_meta.last_synced_at = now
```

觸發：啟動、回到前景、網路恢復、本地寫入（去抖 1 秒）、下拉重新整理。
退避：1s、2s、4s…，上限 5 分鐘；網路恢復與使用者手動重新整理會重設退避。

### UI 狀態（唯一來源）

```dart
sealed class SyncStatus {
  GuestLocalOnly      // 訪客
  Synced              // outbox 無 pending/failed
  Syncing
  Pending(int count)  // count(outbox.state = pending)
  Failed(int count)   // count(outbox.state = failed)
  NeedsReauth         // refresh 失敗
  Offline             // 有 pending 但目前沒有網路（僅提示用）
}
```
由 outbox 筆數的 Stream、引擎的 running 旗標、`AuthState` 與連線狀態組合而成；畫面只讀這個。

## 6. Auth 與帳號切換

- `AuthState`：`Guest` / `SignedIn(user)` / `NeedsReauth(user)`；token 在 secure storage，使用者資料在 `app_meta`。
- **登入成功**：
  - `app_meta.account_id` 為空（訪客）→ 採用此帳號，outbox 開始送出，訪客資料自動上傳。
  - 等於目前登入者 → 繼續。
  - 是**另一個帳號** → 先 `resetLocalData()` 再同步（安全網）。
- **登出**：若有 pending 則提示；確認後 `resetLocalData()`（清空所有同步表、outbox、`sync_cursor`、`app_meta` 的帳號欄位，**保留 `app_settings`**），回到訪客狀態。
- Dio 攔截器：自動帶 token，401 時單一飛行刷新；刷新失敗 → `NeedsReauth`，暫停同步，不阻擋使用。

## 7. 通用同步描述（SyncEntity）

每個實體一份描述，放在 `core/sync/entities.dart`：

```dart
const tripsEntity = SyncEntity(
  name: 'trips', table: 'trips', access: Access.root,
  columns: {'name': Col.text, 'description': Col.text, 'start_date': Col.date,
            'end_date': Col.dateNullable, 'cover_image': Col.textNullable, 'owner_id': Col.textNullable},
);
```

引擎只用描述來：解析伺服器 JSON、組 upsert SQL、疊上 patch、產生推送 patch。
**測試保證**：描述的欄位集合 = Drift 資料表的 `$columns`（扣除 `is_sample` 等僅本地欄位），新增欄位忘了更新描述會讓測試失敗。

## 8. 目錄結構（`app/lib`）

```text
core/
  db/          app_database.dart、tables/*.dart、daos
  sync/        sync_entity.dart、entities.dart、outbox_writer.dart、sync_engine.dart、sync_status.dart
  auth/        auth_state.dart、auth_repository.dart、token_store.dart、dio_client.dart
  settings/    app_settings.dart
features/
  trips/       data/（TripRepository）、domain/（Trip、Role）、ui/
  itinerary/ gear/ meals/ ...
```

Riverpod：`appDatabaseProvider`、`syncEngineProvider`、`syncStatusProvider`（Stream）、`authStateProvider`；各功能的 `xxxListProvider` 都是 `db.watch...()` 的 Stream。

## 9. 測試計畫（記憶體 Drift + 假 API）

1. 寫入同時產生 outbox；交易失敗時兩者都回滾。
2. 合併規則全部情境（第 3.1 節）。
3. 建立後尚未推送就刪除 → outbox 空、伺服器沒收到任何請求。
4. 推送途中失敗、重啟後重送，`op_id` 不變。
5. 拉取不會蓋掉 pending 修改；pending delete 的實體不會復活。
6. tombstone、被移出行程、行程被刪的本地清理。
7. 父列不存在時略過子列。
8. 訪客資料登入後被推送；換帳號登入會清空。
9. 捨棄失敗的「建立行程」會清掉其子操作。
10. 描述與 Drift 欄位一致（第 7 節）。
11. `SyncStatus` 在各種組合下的結果。

## 10. 待確認

| # | 議題 | 我的建議 |
| :-- | :-- | :-- |
| 1 | 個人資料表不存 `user_id` | 同意：本地全是「我的」 |
| 2 | 本地硬刪除，outbox 保存刪除操作 | 同意 |
| 3 | 通用描述表驅動引擎（取代每個實體手寫映射） | 同意，並以測試保證一致 |
| 4 | 時間戳以文字儲存、游標保存伺服器原始字串 | 同意 |
| 5 | 範例行程標記 `is_sample`，只存在本機、不進 outbox | 同意 |
| 6 | 離線地圖下載任務與 FMTC 另行設計 | 同意，做地圖功能時再寫 |
