# 資料庫、Outbox 同步與 Auth 設計

> 2026-11-21 草案。實作依據：`TECH_DECISIONS.md`、`ONBOARDING_NAVIGATION.md`。
> 舊實作（`legacy/backend_legacy/`、`legacy/docs/`）僅作參考。

## 1. 核心原則

1. **本地資料庫是 UI 唯一的資料來源**。畫面只訂閱 Drift Stream，從不直接讀網路結果。
2. **每次本地寫入與對應的 outbox 紀錄在同一個交易內完成**，所以不會「改了資料卻沒排進上傳」。
3. **沒有逐列的 syncStatus**。「N 筆未上傳」就是 `outbox` 的筆數。
4. **應用程式不依賴 token 是否有效**。離線與 token 過期時 App 照常使用，只有同步會暫停。
5. 同步只作用在離線優先資料：行程、成員、節點、裝備、餐食。其餘功能在線讀取，不進 outbox。

## 2. 後端資料表（PostgreSQL，第一版）

所有主鍵為 client 產生的 UUIDv7。可同步的資料表共用以下欄位：

| 欄位 | 說明 |
| :-- | :-- |
| `id UUID PK` | 由 client 產生，因此離線建立不需要伺服器配號 |
| `updated_at TIMESTAMPTZ` | 由觸發器以 `clock_timestamp()` 寫入，**不接受 client 傳入**；同步游標依據 |
| `deleted_at TIMESTAMPTZ NULL` | 刪除標記（tombstone），資料列保留 |
| `created_at`、`created_by`、`updated_by` | 稽核欄位 |

### 資料表

| 表 | 重點欄位 | 備註 |
| :-- | :-- | :-- |
| `users` | email（小寫唯一）、password_hash、display_name、avatar、is_verified、is_active、last_login_at | 移除 `role_id` |
| `refresh_tokens` | id、user_id、token_hash、expires_at、revoked_at、replaced_by | 見第 5 節 |
| `email_verifications` | user_id、code_hash、expires_at、attempts | 6 位數，30 分鐘 |
| `trips` | owner_id、name、description、start_date、end_date、mountain_id（選填，主要山頭）、cover_image | 移除 `is_active`、`day_names` |
| `trip_members` | trip_id、user_id、role（`owner` / `guide` / `member`）、joined_at | 可同步（含 tombstone） |
| `itinerary_items` | trip_id、day_index（0 = D0）、name、est_minutes、altitude、distance、lat、lng、note、checked_in_at | 新增座標以支援離線地圖提示；用 `checked_in_at` 取代舊的兩個重複欄位 |
| `gear_items` | trip_id、**user_id**（這份裝備屬於誰）、name、weight、category、quantity、is_checked、sort_order | 個人資料 |
| `meal_plan_days` | trip_id、**user_id**、name、day_index | 個人資料 |
| `meal_items` | trip_id、**user_id**、meal_plan_day_id、meal_type、name、weight、calories、quantity、note | 個人資料 |
| `processed_ops` | op_id PK、user_id、result JSONB、created_at | 冪等紀錄，保留 30 天 |

裝備組合（可分享、含分享碼）在實作裝備功能時再設計，採用同一套同步欄位。

### 權限

不使用 roles / permissions 資料表，改在程式中以 `trip_members.role` 判斷：

| 操作 | owner | guide | member |
| :-- | :-: | :-: | :-: |
| 檢視行程 | ✓ | ✓ | ✓ |
| 編輯行程、節點（共用資料） | ✓ | ✓ | |
| 編輯**自己的**裝備、餐食（個人資料） | ✓ | ✓ | ✓ |
| 邀請 / 移除成員 | ✓ | ✓ | |
| 刪除行程、移交擁有者 | ✓ | | |
| 建立行程 | 任何已登入使用者 | | |

資料分兩類：
- **共用資料**（行程、成員、節點）：依角色判斷。
- **個人資料**（裝備、餐食）：每筆帶 `user_id`，**只有該成員本人能新增、修改、刪除**，不分角色。
- 第一版個人資料僅本人可見，`/sync/changes` 只回傳自己的裝備與餐食；之後若要讓團員互看，只需放寬拉取條件。
- 行程被刪除或成員被移除時，該成員在此行程的個人資料一併成為 tombstone。

## 3. 同步 API

兩個 endpoint，涵蓋所有離線優先資料（取代舊版每個資源一組 CRUD + 批次 PUT）。

### 3.1 拉取：`GET /sync/changes?since=<ts>&limit=<n>`

- 回傳使用者所屬行程（以及行程本身）在 `since` 之後變更的所有資料列，包含 tombstone，依表分組。
- 回應附 `next_since`（本頁最後一筆的 `updated_at`）與 `has_more`。
- **重疊窗口**：client 請求時使用 `since - 5 秒`。交易提交順序與時間戳順序可能略有不同，重疊可避免漏資料；重複套用沒有副作用，因為套用是冪等的 upsert。
- 首次同步 `since` 為空，等同完整拉取。
- 被移出行程時，伺服器回傳該行程與其子資料的 tombstone，client 清除本地資料。

### 3.2 推送：`POST /sync/push`

請求是一批操作，依 outbox 順序送出：

```json
{ "ops": [
  { "op_id": "uuid", "entity": "itinerary_items", "entity_id": "uuid",
    "type": "upsert", "patch": { "name": "黑水塘", "altitude": 2700 } },
  { "op_id": "uuid", "entity": "gear_items", "entity_id": "uuid", "type": "delete" }
] }
```

- `op_id` 作為冪等鍵：重送相同 `op_id` 直接回傳先前結果。
- **欄位層級 last-write-wins**：`patch` 只含被修改的欄位，伺服器逐欄套用，以抵達順序為準，不比較版本。這避免了「整列覆蓋導致離線修改被吃掉」。
- 每個操作回傳獨立結果：

| 狀態 | 意義 | client 處理 |
| :-- | :-- | :-- |
| `applied` | 成功，附伺服器端完整資料列 | 移除 outbox 項目 |
| `gone` | 目標已被刪除 | 移除 outbox 項目，本地也刪除 |
| `forbidden` / `invalid` | 權限不足或資料不合法（永久錯誤） | 標記失敗，顯示於「同步失敗」 |

- 伺服器在單一交易內處理整批，每個操作先檢查 `trip_members` 權限。

## 4. 本地資料庫（Drift）

與後端對應的資料表使用相同欄位（不含稽核欄位），另加：

| 表 | 用途 |
| :-- | :-- |
| `outbox` | `seq`（自增）、`op_id`、`entity`、`entity_id`、`type`、`patch`（JSON）、`created_at`、`attempts`、`last_error`、`state`（`pending` / `failed`） |
| `app_meta` | 單列：`account_id`（本機資料屬於哪個帳號，訪客為空）、`sync_cursor`、`last_synced_at` |
| `app_settings` | 主題、歡迎頁是否看過、已看過的情境提示 ID 集合（不使用 SharedPreferences） |

開發期規則不變：不寫遷移，`schemaVersion` 維持 1，直接修改資料表並重建。

### 4.1 寫入流程

```text
使用者操作
  └─ Repository.updateX()
       └─ 交易 {
            1. 寫入／修改本地資料列（刪除時直接刪除）
            2. enqueue outbox（見合併規則）
          }
       └─ 通知 SyncEngine（若已登入且有網路則立即嘗試）
```

**outbox 合併規則**（寫入時於同一交易內處理）：

- 同一實體連續的 upsert 合併成一個 patch（後者覆蓋同名欄位）。
- 新建後尚未推送就刪除：兩者一起移除，不送出。
- 刪除行程時，一併移除該行程下尚在 outbox 的子項目操作。

### 4.2 SyncEngine

一個類別，單一流程，同一時間只會有一輪在跑：

```text
sync():
  1. 若未登入（訪客）→ 結束（outbox 保留）
  2. push：依 seq 取出 pending 操作，每批最多 50 筆
       - 網路錯誤 / 5xx / 401 刷新失敗 → 停止本輪，保留，稍後重試（指數退避）
       - applied / gone → 刪除 outbox 項目，並將回傳資料列寫入本地
       - forbidden / invalid → 標記 failed，繼續處理後面的操作
  3. pull：自 sync_cursor - 5 秒起分頁拉取，每頁在一個交易內套用
```

**套用拉取資料的規則**（修正「畫面被舊資料蓋掉」與「已刪除又復活」）：

1. 若該實體在 outbox 有 pending 的 **delete**，略過該筆。
2. 寫入伺服器版本後，**重新疊上 outbox 中該實體尚未送出的 patch**，使用者看到的永遠是最新的本地修改。
3. 收到 tombstone 則刪除本地資料列（連同子資料）。

觸發時機：App 啟動、回到前景、網路恢復、每次本地寫入後（短暫合併）、使用者下拉重新整理。

### 4.3 UI 如何顯示

| 顯示 | 來源 |
| :-- | :-- |
| 「已同步」 | `outbox` 沒有 pending 與 failed 項目，且最近一輪成功 |
| 「同步中」 | SyncEngine 正在執行 |
| 「N 筆未上傳」 | `count(outbox where state = pending)` |
| 「N 筆同步失敗」 | `count(outbox where state = failed)`；可逐筆查看、重試或捨棄 |
| 「尚未登入，資料僅存於本機」 | 訪客 |

## 5. Auth

### 5.1 Token

| 項目 | 設計 | 與舊版差異 |
| :-- | :-- | :-- |
| Access token | JWT，**15 分鐘**，含 `user_id` | 舊版 1 小時，且有黑名單快取 |
| Refresh token | 不透明隨機字串，14 天，**雜湊後存於 `refresh_tokens`**，每次刷新換發新的並撤銷舊的（rotation） | 舊版為 JWT，黑名單存記憶體或 Redis |
| 登出 | 撤銷該 refresh token | |
| 改密碼 / 停用帳號 | 撤銷該使用者所有 refresh token（access token 最多再有效 15 分鐘） | 舊版需黑名單 |
| 重複使用已撤銷的 refresh token | 撤銷該使用者所有 token（疑似外洩） | 新增 |
| 離線寬限期 | **取消**。App 永不因 token 阻擋使用，只暫停同步 | 舊版 7 天 |

這樣可以移除 `pkg/cache`（Memory / Redis）與 JWT 中介層的黑名單比對，後端不需要 Redis。

### 5.2 端點

| 端點 | 說明 |
| :-- | :-- |
| `POST /auth/register` | 建立帳號並寄出驗證碼，**不發 token** |
| `POST /auth/verify-email` | 驗證碼正確後發 token（註冊後直接進入 App，不用再登入一次） |
| `POST /auth/resend-verification` | 重寄驗證碼（限流） |
| `POST /auth/login` | 未驗證回 `403 email_not_verified`，已停用回 `403 account_disabled`；失敗次數限流 |
| `POST /auth/refresh` | 換發 access + refresh |
| `POST /auth/logout` | 撤銷 refresh token |
| `GET/PUT/DELETE /auth/me` | 個人資料 / 更新 / 停用 |
| `POST /auth/change-password` | |
| `GET /users/search` | 邀請成員用（需登入） |

規則沿用舊版：Email 一律轉小寫、bcrypt 雜湊、登入限流只計算失敗。
驗證信寄送：開發環境把驗證碼印在後端 log，正式環境的寄信服務待決定。

### 5.3 Client 端

```text
sealed AuthState
  ├─ Guest                    // 沒有帳號，本機使用
  ├─ SignedIn(user)           // 有有效 session
  └─ NeedsReauth(user)        // refresh 失敗（被撤銷／過期），不阻擋使用，顯示一則可關閉的橫幅
```

- Token 存放於 `flutter_secure_storage`；使用者基本資料與 `account_id` 存放於 `app_meta`。
- Dio 攔截器：自動帶 access token；遇到 401 時**單一飛行（single-flight）刷新**，多個請求共用一次刷新，成功後重送，失敗則進入 `NeedsReauth` 並暫停同步。

### 5.4 訪客模式與帳號切換

**訪客就是尚未登入的本機使用者。** 訪客的寫入照常進入本地資料庫與 outbox，只是 SyncEngine 因未登入而暫停。

- **訪客 → 註冊 / 登入**：SyncEngine 啟動後直接推送 outbox，伺服器以登入者作為 owner。「認領」不需要專用 API。
- **登入既有帳號且本機有訪客資料**：訪客資料與雲端資料並存（ID 不同，不會衝突）。
- **登出**：
  1. 若有 pending 項目，提示「尚有 N 筆未上傳，登出後將遺失」，可選擇先同步或捨棄。
  2. 登出後清空本機已同步的資料並回到訪客狀態（資料都在伺服器上）。
  3. 這避免了「同一支手機換帳號登入看到上一個人資料」。
- `app_meta.account_id` 與登入帳號不一致時，一律先清空再同步，作為安全網。

## 6. 後端分層（Go）

```text
internal/
  auth/      handler → service → repository   註冊、驗證、token
  sync/      handler → service → repository   /sync/changes、/sync/push
  trip/      service + repository             供 sync 內部使用的權限與資料操作（不另開 CRUD endpoint）
  platform/  config、database、middleware、apperror、logger
```

- 第一版後端只開放上述 endpoint，行程等離線優先資料全部走 `/sync/*`，不另做 REST CRUD。
- 在線讀取的資料（山岳資訊、天氣、使用者搜尋）之後各自成為獨立 endpoint。
- SQL 用 sqlc；OpenAPI 先定義 `/health`、`/auth/*`、`/sync/*`。

## 7. 驗證計畫（必須有測試的情境）

1. 離線建立 / 修改 / 刪除後連線，伺服器與本地一致。
2. 推送途中斷線，重送同一 `op_id` 不會重複套用。
3. 兩台裝置修改同一實體的不同欄位，雙方同步後兩個欄位都保留。
4. 拉取回來的舊資料不會蓋掉尚未送出的本地修改。
5. 本地已刪除（尚未推送）時，拉取不會讓它復活。
6. 被移出行程後，本地對應資料被清除。
7. 訪客建立資料 → 註冊 → 資料出現在雲端。
8. refresh token 被撤銷後，App 仍可使用，同步暫停並顯示橫幅。
9. 登出後再以另一個帳號登入，看不到前一個帳號的資料。

## 7.5 實作時定下的細節（2026-11-21）

- **trip_members 的 ID 是確定性的**：`id = UUIDv5(namespace, "<trip_id>:<user_id>")`（namespace 見 `internal/sync/spec.go`）。移除成員後重新邀請，會復活同一列，不會撞到唯一限制；伺服器會拒絕不符合此規則的 ID。
- **擁有者的成員列由伺服器建立**：client 建立行程時不推送擁有者的 trip_members；離線時 UI 以 `trip.owner_id == 我` 判斷擁有者。成員列在下次拉取時回來。
- **同步端點的 SQL**：`/sync/*` 使用「靜態表名與欄位白名單 + 綁定參數」組出 SQL（逐實體欄位規格在 `internal/sync/spec.go`），而非 sqlc——六個實體共用同一套 patch 引擎，比逐實體寫 sqlc 查詢更少出錯。使用者輸入只會成為綁定參數。auth 查詢仍使用 sqlc。
- **Refresh token 重送寬限 10 秒**：client 若沒收到刷新回應而重送舊 token，不會被誤判為被盜用；超過寬限才再出示已輪替的 token，才會撤銷該使用者全部 session。登出或改密碼造成的撤銷只回傳失效，不連坐其他裝置。
- **授權預設拒絕**：中介層只放行白名單中的公開路徑（health、註冊、驗證、登入、refresh、logout），其餘一律要求 token。
- **分頁**：每個實體各自取 `limit` 筆；任一實體被截斷就 `has_more = true`，`next_since` 取被截斷實體中最早的最後一筆時間。其他實體在下一頁可能重複回傳，因為套用是冪等的。
- **單一裝置的待辦**：推送時整批在同一交易，每個操作用 savepoint 隔離；`forbidden` / `invalid` 不影響同批其他操作。

## 8. 決策狀態

第 1～7 項皆已確認（2026-11-21）。

| # | 議題 | 我的建議 |
| :-- | :-- | :-- |
| 1 | 同步衝突採「欄位層級 last-write-wins」（取代先前提的整列版本比較） | 同意；實作簡單，且不會吃掉離線修改 |
| 2 | 取消 JWT 黑名單，改為 15 分鐘 access token + 資料庫 refresh token | 同意；後端不需要 Redis |
| 3 | 取消「離線寬限期」概念 | 同意；App 本身離線可用，token 只影響同步 |
| 4 | 登出時清空本機資料 | 同意，但有 pending 時需警告 |
| 5 | 正式環境的驗證信寄送服務 | 之後決定；開發期先印 log |
| 6 | 裝備、餐食為個人資料，member 可編輯自己的；第一版僅本人可見 | 編輯權限已確認；可見範圍待確認 |
| 7 | 是否導入 Redis | **已決定：第一版不用**；快取與限流先寫成介面，預設記憶體實作，之後可替換 |
