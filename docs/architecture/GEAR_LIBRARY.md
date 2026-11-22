# 裝備庫、範本與雲端分享

> 2026-11-22。取代舊版三套機制（個人裝備庫、雲端裝備組合 gear_sets、templates）。決策來源：使用者確認——
> ① 做「我的裝備庫＋可存成範本」；② 第一版就做雲端分享（公開／Key 保護／私人）；③ 餐食用同一套機制（常用食物庫與範本）。
> 資料表與 API 的最終依據仍是 `backend/migrations/000001_init_schema.up.sql` 與 `backend/api/openapi.yaml`。

## 1. 使用者看到的東西

| 入口 | 行為 |
| :-- | :-- |
| 裝備／餐食新增表單 | 輸入名稱時，從「我的裝備庫／常用食物」建議（選了會帶入分類、重量、熱量）。新增項目時若庫裡沒有同名項目，自動加入庫（之後可在庫裡改或刪） |
| 「我的」→「我的裝備庫」 | 兩個分頁：裝備、食物。可編輯、刪除、手動新增 |
| 裝備／餐食分段的溢出選單 | 「存成範本」：把這個行程的裝備與餐食存成一份範本（取名）。「套用範本」：選一份範本，把項目加入這個行程（加入，不覆蓋；餐食依天數對應，缺的天數自動建立） |
| 「我」→「我的範本」 | 範本列表：改名、刪除、分享到雲端、查看內容 |
| 「雲端裝備組合」 | 瀏覽公開組合、我分享的組合；點開看內容（受保護的要輸入 Key）；可「存成我的範本」或「加到這個行程」 |

規則：
- 裝備庫、範本只屬於個人，登入後跨裝置同步；訪客存在本機，登入後收編（與其他個人資料相同）。
- 雲端分享需要登入與網路；瀏覽公開組合需要網路，不需要登入（但下載受保護內容需要 Key）。
- 套用或下載他人組合只會「複製」到自己的資料，之後各自獨立。

## 2. 資料表

個人資料沿用同步機制（欄位級最後寫入為準、tombstone、op_id 冪等）。庫與範本**不屬於任何行程**，所以後端新增一種存取型態 `accessOwner`：列的 `user_id` 必須等於操作者，沒有 trip 關聯。

```sql
-- 個人可重用項目（裝備或食物），會同步
CREATE TABLE library_items (
    id         UUID PRIMARY KEY,
    user_id    UUID             NOT NULL REFERENCES users(id),
    kind       VARCHAR(10)      NOT NULL CHECK (kind IN ('gear', 'meal')),
    name       VARCHAR(200)     NOT NULL DEFAULT '',
    category   VARCHAR(50)      NOT NULL DEFAULT 'other',   -- 裝備：裝備分類；食物：餐別（breakfast/lunch/dinner/snack/other）
    weight     DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (weight >= 0),
    calories   DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (calories >= 0),
    note       TEXT             NOT NULL DEFAULT '',
    deleted_at, created_at, created_by, updated_at, updated_by   -- 同其他同步表
);

-- 個人範本，會同步。項目以 JSON 存在同一列（不另開子表，避免 tombstone 連鎖）
CREATE TABLE templates (
    id         UUID PRIMARY KEY,
    user_id    UUID         NOT NULL REFERENCES users(id),
    title      VARCHAR(200) NOT NULL DEFAULT '',
    note       TEXT         NOT NULL DEFAULT '',
    items      TEXT         NOT NULL DEFAULT '[]',   -- JSON 陣列，格式見下
    deleted_at, created_at, created_by, updated_at, updated_by
);
```

`items` 與雲端分享共用同一個項目格式（最多 300 項）：

```json
[
  {"kind":"gear","name":"睡袋","category":"sleep","weight":900,"quantity":1,"note":""},
  {"kind":"meal","name":"飯糰","category":"lunch","weight":180,"calories":320,"quantity":2,"day":1,"note":""}
]
```

- `kind=gear`：`category` 為裝備分類；`weight` 單位公克。
- `kind=meal`：`category` 為餐別；`day` 為第幾天（從 1 開始）；`calories` 單位大卡。

雲端分享（**不走同步**，線上操作）：

```sql
CREATE TABLE shared_sets (
    id             UUID PRIMARY KEY,
    owner_id       UUID         NOT NULL REFERENCES users(id),
    title          VARCHAR(200) NOT NULL,
    author_name    VARCHAR(100) NOT NULL,          -- 分享當下的暱稱快照
    visibility     VARCHAR(10)  NOT NULL CHECK (visibility IN ('public', 'protected', 'private')),
    access_key_hash TEXT,                            -- protected 才有；bcrypt
    items          JSONB        NOT NULL,           -- 同上格式
    total_weight   DOUBLE PRECISION NOT NULL DEFAULT 0,   -- 裝備總重（公克，含數量）
    gear_count     INT          NOT NULL DEFAULT 0,
    meal_count     INT          NOT NULL DEFAULT 0,
    deleted_at     TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX idx_shared_sets_public ON shared_sets(created_at DESC) WHERE visibility <> 'private' AND deleted_at IS NULL;
CREATE INDEX idx_shared_sets_owner  ON shared_sets(owner_id, created_at DESC) WHERE deleted_at IS NULL;
```

可見性：
- `public`：所有人可列出、可看內容。
- `protected`：所有人可列出（看得到標題與摘要），看內容需要 Key；擁有者免 Key。
- `private`：只有擁有者看得到（等於雲端備份一份）。

Key：4～12 個英數字，由分享者自訂；伺服器只存雜湊。猜 Key 有流量限制（沿用既有 ratelimit），錯誤時一律回「Key 不正確」。

## 3. 雲端分享 API（線上、需要 `bearerAuth` 的標示）

| 方法與路徑 | 登入 | 說明 |
| :-- | :-- | :-- |
| `GET /shared-sets?scope=public\|mine&q=&limit=&cursor=` | public 不需要，mine 需要 | 摘要列表（不含 items），依建立時間新到舊；`scope=public` 含 protected 但不含 private |
| `POST /shared-sets` | 需要 | 建立：`{title, visibility, access_key?, items[]}`；protected 必須有 key；items 最多 300；回傳摘要 |
| `GET /shared-sets/{id}` | 視可見性 | 詳情含 items。protected 且非擁有者要帶標頭 `X-Access-Key`；private 只有擁有者；找不到與無權限都回 404（不洩漏存在） |
| `DELETE /shared-sets/{id}` | 需要（擁有者） | 軟刪除 |

摘要欄位：`id, title, author_name, visibility, total_weight, gear_count, meal_count, created_at, mine(bool)`。

## 4. 前端

- 新 Drift 表：`library_items`、`templates`（`items` 為 JSON 文字）。屬於同步實體（`library_items`、`templates`），沿用 outbox。
- 新 feature 資料夾：`features/library/`（`data / domain / ui`）。
- 項目格式的編解碼與「套用範本到行程」的邏輯放在 `domain`，純函式，容易測。
- 套用範本：裝備直接加入行程裝備（同名同分類且已存在則略過）；餐食依 `day` 對應到行程的餐食天（缺的建立）。
- 雲端：`SharedSetsApi`（Dio）；列表與詳情不快取到資料庫（線上才有）。

## 5. 不做／之後再說

- 評分、下載次數、留言、舉報與審核（第二期；第一版公開內容靠擁有者自行刪除）。
- 範本的版本與更新通知。
- 圖片。
