# 揪團活動（第二期）

> 2026-11-22。取代舊版 `group_events*`。決策來源：使用者確認「第二期先做揪團」。
> 與裝備雲端分享相同：**線上功能，不走同步**；資料表與 API 的最終依據仍是 `backend/migrations/000001_init_schema.up.sql` 與 `backend/api/openapi.yaml`。
> 下列「預設」是設計時的假設，使用者可以推翻，改動只需要更新本文件與契約。

## 1. 使用者看到的東西

| 入口 | 行為 |
| :-- | :-- |
| 「揪團」頁籤 | 頂端分「找團｜我的團」。主辦的揪團有待審核申請時，頁籤圖示、「我的團」與「我主辦的」顯示數量 |
| 揪團列表 | 找團：全部、即將出發、熱門；我的團（需登入）：我參加的、我主辦的；搜尋標題或地點；每張卡片顯示標題、分類、地點、日期、人數（已通過／上限）、按讚數、留言數 |
| 揪團詳情 | 標題、分類、主辦人、地點、日期、人數、說明、行程路線預覽（快照）、隊員私密留言（鎖定／解鎖）、公開留言、按讚、底部動態按鈕（申請加入／審核中／已加入／再次申請） |
| 建立／編輯揪團（登入） | 標題、分類、地點、日期、人數上限、說明、是否需審核、隊員私密留言、可選「連結現有行程」 |
| 主辦人管理（登入） | 申請名單：通過／拒絕（可填拒絕原因）；編輯、取消揪團 |

規則：
- 瀏覽列表與詳情不需要登入；申請、留言、按讚、建立、舉報需要登入。訪客點到時顯示「登入後使用」。
- **私密留言**只給主辦人與已通過者；其他人拿到的欄位是 null，詳情另給 `private_message_locked: true`。伺服器不會把內容送給無權限的人。
- **連結行程**：主辦人只能連結自己是團長的行程。通過申請時，伺服器自動把申請人加入該行程成員（角色：隊員）；申請人被移除或退出時，伺服器同步移除成員（走既有的 trip_members 軟刪除，客戶端經一般同步收到）。取消揪團不會動行程成員。
- **行程快照**：建立或更新時由客戶端送出一份簡化的行程內容（見 §3），讓未加入的人預覽路線。快照只是展示用，與連結行程之後的修改無關；主辦人可以在編輯時重新送出。
- 人數：`approved_count >= max_members` 時不能再通過申請（回 409 `event_full`）；不需審核的揪團，申請當下就是通過（同樣受人數限制）。
- 狀態：`open`（可申請）、`closed`（主辦人關閉報名，現有成員不變）、`cancelled`（主辦人取消，列表不顯示，詳情仍可由參與者看到）。已過期（`start_date` 在今天之前）的揪團仍可看，但不能申請。
- 留言：任何登入者可留言（1～1000 字）；作者與主辦人可刪除。按讚：每人一次，可取消。
- 舉報：登入者可以對揪團或留言送出舉報（原因 1～500 字）；第一版只存起來，沒有審核介面（營運人員直接查資料庫），同一人對同一目標只記一次。
- 隱私：公開資訊只含主辦人的暱稱與頭像；Email 與帳號 ID 不外洩。申請名單（主辦人才看得到）顯示申請人的暱稱、頭像與報名訊息。

## 2. 資料表

```sql
CREATE TABLE group_events (
    id                UUID PRIMARY KEY,
    host_id           UUID         NOT NULL REFERENCES users(id),
    title             VARCHAR(200) NOT NULL,
    description       TEXT         NOT NULL DEFAULT '',
    category          VARCHAR(20)  NOT NULL CHECK (category IN ('hiking', 'camping', 'bouldering', 'other')),
    location          VARCHAR(200) NOT NULL DEFAULT '',
    start_date        DATE         NOT NULL,
    end_date          DATE,
    max_members       INT          NOT NULL CHECK (max_members BETWEEN 2 AND 100),
    approval_required BOOLEAN      NOT NULL DEFAULT TRUE,
    private_message   TEXT         NOT NULL DEFAULT '',
    status            VARCHAR(10)  NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled')),
    linked_trip_id    UUID         REFERENCES trips(id),
    trip_snapshot     JSONB,
    snapshot_updated_at TIMESTAMPTZ,
    created_at, updated_at (clock_timestamp, trigger like others), deleted_at TIMESTAMPTZ,
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE group_event_applications (
    id               UUID PRIMARY KEY,
    event_id         UUID        NOT NULL REFERENCES group_events(id),
    user_id          UUID        NOT NULL REFERENCES users(id),
    status           VARCHAR(10) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    message          VARCHAR(500) NOT NULL DEFAULT '',
    rejection_reason VARCHAR(500) NOT NULL DEFAULT '',
    created_at, updated_at,
    UNIQUE (event_id, user_id)            -- 再次申請會更新同一列
);

CREATE TABLE group_event_comments (
    id UUID PRIMARY KEY, event_id UUID NOT NULL REFERENCES group_events(id), user_id UUID NOT NULL REFERENCES users(id),
    body VARCHAR(1000) NOT NULL, created_at, deleted_at
);

CREATE TABLE group_event_likes (
    event_id UUID NOT NULL REFERENCES group_events(id), user_id UUID NOT NULL REFERENCES users(id),
    created_at, PRIMARY KEY (event_id, user_id)
);

CREATE TABLE reports (
    id UUID PRIMARY KEY, reporter_id UUID NOT NULL REFERENCES users(id),
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('group_event', 'group_event_comment')),
    target_id UUID NOT NULL, reason VARCHAR(500) NOT NULL, created_at,
    UNIQUE (reporter_id, target_type, target_id)
);
```

索引：列表（`start_date`、`created_at`）、`host_id`、`(event_id, status)`、`(event_id, created_at)`；開發階段不加遷移檔，直接改 `000001`。

## 3. API 契約

所有路徑在 `/api/v1` 下。`optional auth`＝沒帶 token 也可以，帶了無效 token 回 401（與 `/shared-sets` 相同做法）。

**共用物件**

```jsonc
// GroupEventSummary
{ "id": "uuid", "title": "…", "category": "hiking|camping|bouldering|other", "location": "…",
  "start_date": "2026-12-05", "end_date": "2026-12-07"|null, "max_members": 8,
  "approved_count": 3, "pending_count": 0 (待審核人數，非主辦人一律 0), "like_count": 12, "comment_count": 5,
  "status": "open|closed|cancelled", "approval_required": true,
  "host": {"display_name": "陳大山", "avatar": "🐻"}, "created_at": "…",
  "liked": false, "my_status": null|"pending"|"approved"|"rejected"|"cancelled", "is_host": false }

// GroupEventDetail = Summary + 
{ "description": "…", "private_message": "…"|null, "private_message_locked": true|false,
  "my_rejection_reason": "…"|null, "linked_trip_id": "uuid"|null (host only; null for others),
  "trip_snapshot": TripSnapshot|null, "snapshot_updated_at": "…"|null }

// TripSnapshot (客戶端送、伺服器驗證大小：最多 200 個節點、整體 ≤ 64 KB)
{ "name": "嘉明湖三日", "start_date": "2026-12-05", "end_date": "2026-12-07"|null,
  "itinerary": [ {"day": 1, "name": "向陽登山口", "time": "07:00"|null, "altitude": 2300, "lat": 23.3|null, "lng": 121.0|null} ] }

// Application (host only)
{ "id": "uuid", "user": {"display_name": "…", "avatar": "…"}, "status": "pending|approved|rejected|cancelled",
  "message": "…", "created_at": "…" }

// Comment
{ "id": "uuid", "user": {"display_name": "…", "avatar": "…"}, "body": "…", "created_at": "…", "mine": false }
```

**端點**

| 方法與路徑 | 登入 | 說明 |
| :-- | :-- | :-- |
| `GET /group-events?scope=all\|upcoming\|popular\|joined\|hosting&q=&limit=&cursor=` | all／upcoming／popular 為 optional；joined、hosting 需要 | 回 `{items:[GroupEventSummary], next_cursor?}`。`all`＝未取消、依建立時間新到舊；`upcoming`＝未取消且 `start_date >= 今天`，依日期近到遠；`popular`＝未取消，依（按讚數＋已通過人數）高到低再依建立時間；`joined`＝我申請過且狀態為 pending 或 approved；`hosting`＝我主辦的（含已取消）。`q` 搜標題與地點（不分大小寫、跳脫萬用字元）。`limit` 預設 20、最大 50。`popular` 用 offset 式 cursor 也可以（cursor 為不透明字串） |
| `POST /group-events` | 需要 | 建立。欄位：`title`(5..200)、`category`、`location`(≤200)、`start_date`、`end_date?`、`max_members`(2..100)、`approval_required`、`description`(≤4000)、`private_message`(≤2000)、`linked_trip_id?`、`trip_snapshot?`。連結行程時檢查呼叫者是該行程的 owner 成員，否則 403 `not_trip_owner`。主辦人自動不算在申請人數內。回 201 `GroupEventDetail` |
| `GET /group-events/{id}` | optional | 詳情；已取消的揪團只有主辦人與申請過的人看得到，其他人 404 |
| `PATCH /group-events/{id}` | 主辦人 | 可改上述欄位與 `status`(open/closed)；`max_members` 不可小於目前已通過人數；更換 `linked_trip_id` 時不會移除既有成員 |
| `DELETE /group-events/{id}` | 主辦人 | 取消（status=cancelled，不實際刪除）；204 |
| `POST /group-events/{id}/apply` | 需要 | body `{message?}`。主辦人不能申請（409 `host_cannot_apply`）；已 pending／approved 時 409 `already_applied`；`rejected`／`cancelled` 可以再次申請（更新同一列）；`closed`／`cancelled`／已過期回 409 `registration_closed`；不需審核的揪團直接 approved（並加入連結行程成員），已滿回 409 `event_full`。回 200 `{my_status}` |
| `DELETE /group-events/{id}/apply` | 需要 | 取消申請或退出：pending→cancelled，approved→cancelled（並移除連結行程成員）；204 |
| `GET /group-events/{id}/applications?status=` | 主辦人 | `{items:[Application]}`，依申請時間；`status` 可篩選（預設 pending 與 approved） |
| `POST /group-events/{id}/applications/{appId}/review` | 主辦人 | body `{approve: bool, reason?: string}`；只能審核 pending；通過時檢查人數（409 `event_full`）並加入連結行程成員；拒絕可附原因。回 200 `Application` |
| `DELETE /group-events/{id}/applications/{appId}` | 主辦人 | 移除已通過的成員（status→cancelled 並移除行程成員）；204 |
| `GET /group-events/{id}/comments?limit=&cursor=` | optional | `{items:[Comment], next_cursor?}`，舊到新 |
| `POST /group-events/{id}/comments` | 需要 | body `{body}`；回 201 `Comment` |
| `DELETE /group-events/{id}/comments/{commentId}` | 作者或主辦人 | 軟刪除；204 |
| `PUT /group-events/{id}/like`、`DELETE /group-events/{id}/like` | 需要 | 冪等；回 200 `{liked, like_count}` |
| `POST /reports` | 需要 | body `{target_type, target_id, reason}`；目標必須存在；同一人重複舉報回 200（不重複記錄）；201 第一次 |

**錯誤碼**（除標準 401 `unauthorized`、404 `group_event_not_found`、403 `forbidden`、400 驗證錯誤外）：`not_trip_owner`、`host_cannot_apply`、`already_applied`、`registration_closed`、`event_full`、`invalid_snapshot`、`invalid_review`。

**加入／移除行程成員**（連結行程時）：使用既有的確定性 id 規則 `MemberID(trip, user)`（見 `backend/internal/sync/spec.go`），新增或復活 `trip_members` 一列（role=member，`created_by`/`updated_by`=主辦人），移除時設 `deleted_at`。這與一般同步的成員邏輯一致，客戶端經 `/sync/changes` 收到。

## 4. 前端

- 新 feature：`features/events/`（`data / domain / ui`）。API 用 `authedDioProvider`（optional auth 端點也走它，沒有 token 時就不帶）。
- 不寫入本機資料庫（線上資料）；列表與詳情用 Riverpod 的 Future 狀態，下拉重新整理。
- 「揪團」是底部導覽的獨立頁籤（路由 `/events`），頂端 `SegmentedButton`（找團｜我的團），兩邊各自保留搜尋與篩選。
- 待審核數量＝我主辦、未取消、未過期揪團的 `pending_count` 總和。登入時、點頁籤時、審核或移除後重新抓取；不輪詢、不推播，抓不到就不顯示。
- 建立揪團可「連結現有行程」：只列出我是團長的本機行程；快照由前端從本機行程資料組出（節點依天數與時間排序，最多 200 個）。
- 詳情頁底部動態按鈕依 `is_host / my_status / status / approved_count` 決定；主辦人另有「管理申請」與「編輯／取消」。
- 離線時顯示「需要連線」與重試，不顯示過期內容。

## 5. 不做／之後再說

- 揪團內的群組聊天、通知（站內或推播）：第三期。通過／拒絕目前只在使用者再次開啟詳情時看到。
- 評分、黑名單、審核後台、自動偵測不當內容。
- 候補名單。
- 揪團加入收藏（等收藏功能做完再加）。
