# 行程討論（留言、投票）與收藏（第二期）

> 2026-11-22。決策來源：使用者確認——留言與投票「離線優先，和行程一起同步」；收藏先做山岳（離線可用、跨裝置同步），揪團做好後再加揪團。
> 資料表與 API 的最終依據仍是 `backend/migrations/000001_init_schema.up.sql` 與 `backend/api/openapi.yaml`。「預設」是設計時的假設，使用者可推翻。

## 1. 使用者看到的東西

| 入口 | 行為 |
| :-- | :-- |
| 行程詳情新增分段「討論」 | 上半是留言板，下半是投票。分段順序：行程、裝備、餐食、討論、成員與天氣 |
| 留言板 | 所有成員都能發言、回覆（只有一層回覆）、刪除自己的留言；團長與嚮導可以刪除任何人的留言。離線也能發，之後同步 |
| 投票 | 團長與嚮導建立投票（標題、說明、選項、截止時間、單選或多選、是否允許成員新增選項、是否盲投）；所有成員都能投票（離線也可）；結束或刪除由團長與嚮導決定 |
| 投票結果 | 預設即時顯示每個選項的票數與投票者；盲投的投票在結束或截止後才顯示結果（成員只看得到自己投了什麼） |
| 探索列表與山岳詳情 | 愛心：點一下收藏／取消；探索列表多一個「已收藏」篩選；離線可用，登入後跨裝置同步 |
| 「我」分頁 | 「我的收藏」：已收藏的山岳列表 |

預設與規則：
- 留言內容 1～1000 字；一層回覆（回覆不能再被回覆）。顯示名稱與頭像從成員列表取得（`trip_members` 已含 `display_name`、`avatar`），留言本身不存名稱。
- 離開或被移出行程的人，其留言仍保留顯示，名稱改為「已離開的成員」（找不到成員列時）。
- 投票：標題 1～200 字；選項 2～20 個，每個 1～100 字；多選不限制票數；單選時每人只算最新的一票。投票結果以同步下來的票列計算（客戶端算，不由伺服器彙總）。
- 截止時間過了視同結束（客戶端以裝置時間判斷顯示；伺服器不拒絕過期投票，避免離線補投被擋——投票是軟性的團隊決定，不是安全邊界）。
- 收藏只存山岳 ID；山岳資料來自既有的山岳清單。

## 2. 資料表（皆為同步實體）

沿用既有同步機制（欄位級最後寫入為準、tombstone、op_id 冪等、拉取依 `updated_at`）。後端 `internal/sync/spec.go` 新增實體與存取規則。

```sql
-- 留言（行程成員共享）
CREATE TABLE trip_messages (
    id         UUID PRIMARY KEY,
    trip_id    UUID         NOT NULL REFERENCES trips(id),
    user_id    UUID         NOT NULL REFERENCES users(id),   -- 作者，建立時強制為操作者
    parent_id  UUID         REFERENCES trip_messages(id),     -- 只允許一層：parent 本身不能有 parent
    body       VARCHAR(1000) NOT NULL,
    deleted_at, created_at, created_by, updated_at, updated_by
);

-- 投票（團長／嚮導管理）
CREATE TABLE polls (
    id         UUID PRIMARY KEY,
    trip_id    UUID         NOT NULL REFERENCES trips(id),
    title      VARCHAR(200) NOT NULL,
    description TEXT        NOT NULL DEFAULT '',
    deadline   TIMESTAMPTZ,
    allow_multiple   BOOLEAN NOT NULL DEFAULT FALSE,
    allow_add_option BOOLEAN NOT NULL DEFAULT FALSE,
    blind      BOOLEAN      NOT NULL DEFAULT FALSE,
    status     VARCHAR(10)  NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    deleted_at, created_at, created_by, updated_at, updated_by
);

CREATE TABLE poll_options (
    id         UUID PRIMARY KEY,
    poll_id    UUID         NOT NULL REFERENCES polls(id),
    trip_id    UUID         NOT NULL REFERENCES trips(id),
    text       VARCHAR(100) NOT NULL,
    sort_order INT          NOT NULL DEFAULT 0,
    deleted_at, created_at, created_by, updated_at, updated_by
);

-- 一個人對一個選項的一票。id 是確定性的（UUIDv5 of "<option_id>:<user_id>"），重新投票＝復活同一列
CREATE TABLE poll_votes (
    id         UUID PRIMARY KEY,
    poll_id    UUID NOT NULL REFERENCES polls(id),
    option_id  UUID NOT NULL REFERENCES poll_options(id),
    trip_id    UUID NOT NULL REFERENCES trips(id),
    user_id    UUID NOT NULL REFERENCES users(id),
    deleted_at, created_at, created_by, updated_at, updated_by   -- deleted_at = 收回這一票
);

-- 收藏（個人，沒有行程）
CREATE TABLE favorites (
    id         UUID PRIMARY KEY,
    user_id    UUID         NOT NULL REFERENCES users(id),
    kind       VARCHAR(20)  NOT NULL CHECK (kind IN ('mountain')),
    target_id  VARCHAR(100) NOT NULL,                         -- 山岳 ID（如 beidawu）
    deleted_at, created_at, created_by, updated_at, updated_by
);
```

存取規則（`accessXxx` 型態，延伸既有 `accessRoot / accessMember / accessShared / accessPersonal / accessOwner`）：

| 實體 | 讀取 | 建立 | 修改 | 刪除 |
| :-- | :-- | :-- | :-- | :-- |
| `trip_messages` | 該行程所有成員 | 任何有效成員；`user_id` 強制為操作者；`parent_id` 必須指向同行程、本身沒有 parent 的留言 | 只有作者可改 `body` | 作者，或團長／嚮導 |
| `polls` | 所有成員 | 團長／嚮導 | 團長／嚮導 | 團長／嚮導 |
| `poll_options` | 所有成員 | 團長／嚮導；成員只有在該投票 `allow_add_option=true` 且 `status=open` 時可新增 | 團長／嚮導；成員只能改自己新增的 | 團長／嚮導；成員只能刪自己新增的 |
| `poll_votes` | 所有成員（盲投的隱藏由客戶端處理） | 任何有效成員，`user_id` 強制為操作者，`option_id` 必須屬於該 `poll_id` 與同一行程；id 必須是確定性規則 | 只有投票人（復活／收回） | 只有投票人 |
| `favorites` | 只有本人 | 本人 | 本人 | 本人 |

「有效成員」＝該行程的未刪除成員。行程被刪除時，上述子列隨行程一起視為消失（與裝備等一致）。

## 3. 前端

- Drift 新表：`trip_messages`、`polls`、`poll_options`、`poll_votes`、`favorites`；新同步實體描述；`resetLocalData` 一併清除；`LocalStore` 的 trip 子表清單加入前四個（它們有 `trip_id`）。
- 新 feature：`features/collab/`（留言、投票）、`features/favorites/`。
- 留言與投票的寫入走既有的 repository＋outbox 同一交易模式；`poll_votes` 的 id 用與後端相同的 UUIDv5 規則。
- 投票結果、單選最新一票、盲投顯示、截止判斷都是純函式，單元測試。
- 探索列表愛心與「已收藏」篩選、山岳詳情愛心、「我的收藏」頁。

## 4. 不做／之後再說

- 留言編輯歷史、@提及、附圖（照片上傳做了之後再加）。
- 通知（有新留言或新投票）：第三期。
- 收藏揪團活動：等揪團完成後再加 `kind='group_event'`。
