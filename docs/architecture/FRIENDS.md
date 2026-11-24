# 好友（Friends）

雙方同意制（類似 Facebook）。**僅線上 API，不是同步實體**，不進 outbox / Drift 同步流程；風格同 `backend/internal/groupevents`。

## 規則

- 一對使用者只有一筆資料，不論誰先邀請。
- 對方已寄邀請給我時，我再邀請他 = 直接成為好友（`accepted`，回 201）。
- 已是好友再邀請 -> 200 `accepted`；我已邀請過 -> 200 `pending`；皆不新增資料。
- 婉拒或取消邀請 = 刪除該筆資料，之後可再次邀請。
- 解除好友為冪等（沒有好友關係也回 204），只刪 `accepted` 的資料，不影響 pending 邀請。
- 只有 `is_active` 且 `is_verified` 的人會出現在列表，也只有這些人可被邀請。API 永遠不回傳 e-mail。
- 限制：每位使用者每小時最多 20 筆**新**邀請（重複送出、交叉自動接受不計）；等待回覆的送出邀請最多 100 筆。
- 刪除帳號時（`auth.Service.DeleteAccount`，與停用帳號同一個 transaction）刪除該人所有好友關係與邀請。

## 資料表

`friendships`（定義在 `backend/migrations/000001_init_schema.up.sql`）

| 欄位 | 說明 |
|---|---|
| id | UUID，主鍵 |
| requester_id / addressee_id | 邀請人 / 被邀請人，`<>` 檢查，FK users |
| status | `pending` / `accepted` |
| created_at | 邀請時間 |
| responded_at | 接受時間（好友「since」） |

唯一索引 `(LEAST(requester_id, addressee_id), GREATEST(...))` 保證一對一筆；另有 requester、addressee 索引。並發的交叉邀請以 `pg_advisory_xact_lock`（依使用者對）序列化。

## API（Bearer，JSON）

| 方法 路徑 | 結果 |
|---|---|
| `GET /friends` | 200 `{friends:[{user_id, display_name, avatar, since}], incoming:[{request_id, user:{id, display_name, avatar}, created_at}], outgoing:[同 incoming]}` |
| `POST /friends/requests` `{user_id}` | 201 新邀請或交叉自動接受；200 無變化；body `{status:"pending"\|"accepted", request_id}` |
| `POST /friends/requests/{request_id}/accept` | 204；僅被邀請人且 pending |
| `DELETE /friends/requests/{request_id}` | 204；被邀請人婉拒或邀請人取消 pending 邀請 |
| `DELETE /friends/{user_id}` | 204；解除好友（冪等） |

錯誤：`cannot_friend_self` 400、`user_not_found` 404（不存在或未啟用）、`too_many_requests` 429、`too_many_pending_requests` 409、`friend_request_not_found` 404（不存在、已接受、或與我無關）、accept 的非被邀請人 `forbidden` 403。

## 揪團整合

揪團 JSON 中所有人物物件（主辦人 `host`、申請者與留言者 `user`）多帶 `id`（uuid），讓 App 能顯示「加好友」。仍不含 e-mail；私密留言規則不變。

## 決策

- 邀請限流用 `platform/ratelimit` 的記憶體實作，與其他模組一致（多實例時需換 Redis）。
- 婉拒不留紀錄（刪除列），代價是無法阻止同一人反覆邀請，由每小時 20 筆限制緩解；封鎖功能暫不做。
- 好友列表依名稱排序、邀請依時間新到舊；目前不分頁。
