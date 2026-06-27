# API Contract

## Go Backend RESTful API

後端已遷移至 Go (Chi + PostgreSQL)，採用 OpenAPI 3.0 規格定義。所有端點以 `/api/v1` 為前綴，使用標準 HTTP Method 與 JSON 格式。

### 認證機制

需認證的端點必須在 Request Header 中帶入 JWT：

```
Authorization: Bearer <access_token>
```

> [!NOTE]
> 本文件以 `backend/api/openapi.yaml` 為單一可信源 (Single Source of Truth) 同步維護。
> 路徑參數採 OpenAPI 原始命名 (`{tripId}`, `{itemId}`, `{id}` 等)。

### 系統 / 健康檢查

| Method | Path             | 說明           | 認證 |
| :----- | :--------------- | :------------- | :--- |
| `GET`  | `/health`        | 健康檢查       | 無   |
| `POST` | `/logs`          | 上傳 App 日誌  | 無   |
| `POST` | `/system/heartbeat` | 心跳與統計同步 | JWT  |
| `GET`  | `/system/flags`  | 取得系統旗標   | 無   |
| `POST` | `/system/flags`  | 更新系統旗標   | 無   |

### 認證 (Auth)

| Method   | Path                        | 說明                      | 認證 |
| :------- | :-------------------------- | :------------------------ | :--- |
| `POST`   | `/auth/register`            | 註冊                      | 無   |
| `POST`   | `/auth/login`               | 登入                      | 無   |
| `POST`   | `/auth/refresh`             | 刷新 Token                | 無   |
| `POST`   | `/auth/verify-email`        | 驗證信箱                  | 無   |
| `POST`   | `/auth/resend-verification` | 重發驗證碼                | 無   |
| `POST`   | `/auth/logout`              | 登出 (Token 加入黑名單)   | JWT  |
| `POST`   | `/auth/change-password`     | 修改密碼 (Token 加入黑名單) | JWT  |
| `GET`    | `/auth/me`                  | 取得當前使用者            | JWT  |
| `PUT`    | `/auth/me`                  | 更新個人資料              | JWT  |
| `DELETE` | `/auth/me`                  | 停用帳號 (軟刪除)         | JWT  |

### 使用者 (Users)

| Method | Path             | 說明                       | 認證 |
| :----- | :--------------- | :------------------------- | :--- |
| `GET`  | `/users/search`  | 以 Email 搜尋使用者        | JWT  |
| `GET`  | `/users/{userId}`| 以 ID 取得使用者資料       | JWT  |

### 行程 (Trips)

| Method   | Path                           | 說明           | 認證 |
| :------- | :----------------------------- | :------------- | :--- |
| `GET`    | `/trips`                       | 行程列表       | JWT  |
| `POST`   | `/trips`                       | 建立行程       | JWT  |
| `GET`    | `/trips/{tripId}`              | 行程詳情       | JWT  |
| `PUT`    | `/trips/{tripId}`              | 更新行程       | JWT  |
| `DELETE` | `/trips/{tripId}`              | 刪除行程       | JWT  |
| `POST`   | `/trips/{tripId}/transfer`     | 移交團長       | JWT  |
| `GET`    | `/trips/{tripId}/members`      | 成員列表       | JWT  |
| `POST`   | `/trips/{tripId}/members`      | 新增成員       | JWT  |
| `DELETE` | `/trips/{tripId}/members/{userId}` | 移除成員   | JWT  |

### 行程節點 (Itinerary)

| Method   | Path                                | 說明         | 認證 |
| :------- | :---------------------------------- | :----------- | :--- |
| `GET`    | `/trips/{tripId}/itinerary`         | 行程節點列表 | JWT  |
| `POST`   | `/trips/{tripId}/itinerary`         | 新增節點     | JWT  |
| `PUT`    | `/trips/{tripId}/itinerary/{itemId}`| 更新節點     | JWT  |
| `DELETE` | `/trips/{tripId}/itinerary/{itemId}`| 刪除節點     | JWT  |

### 行程裝備 (Trip Gear)

| Method   | Path                            | 說明         | 認證 |
| :------- | :------------------------------ | :----------- | :--- |
| `GET`    | `/trips/{tripId}/gear`          | 行程裝備列表 | JWT  |
| `POST`   | `/trips/{tripId}/gear`          | 新增裝備     | JWT  |
| `PUT`    | `/trips/{tripId}/gear/{itemId}` | 更新裝備     | JWT  |
| `DELETE` | `/trips/{tripId}/gear/{itemId}` | 刪除裝備     | JWT  |

### 行程糧食 (Trip Meals)

| Method   | Path                                      | 說明             | 認證 |
| :------- | :---------------------------------------- | :--------------- | :--- |
| `GET`    | `/trips/{tripId}/meal-plan-days`          | 糧食計畫天數列表 | JWT  |
| `POST`   | `/trips/{tripId}/meal-plan-days`          | 新增糧食天數     | JWT  |
| `PUT`    | `/trips/{tripId}/meal-plan-days/{dayId}`  | 更新糧食天數     | JWT  |
| `DELETE` | `/trips/{tripId}/meal-plan-days/{dayId}`  | 刪除糧食天數     | JWT  |
| `GET`    | `/trips/{tripId}/meals`                   | 行程食物列表     | JWT  |
| `POST`   | `/trips/{tripId}/meals`                   | 新增食物         | JWT  |
| `PUT`    | `/trips/{tripId}/meals/{itemId}`          | 更新食物         | JWT  |
| `DELETE` | `/trips/{tripId}/meals/{itemId}`          | 刪除食物         | JWT  |

### 留言板 (Messages)

| Method   | Path                                  | 說明     | 認證 |
| :------- | :------------------------------------ | :------- | :--- |
| `GET`    | `/trips/{tripId}/messages`            | 留言列表 | JWT  |
| `POST`   | `/trips/{tripId}/messages`            | 新增留言 | JWT  |
| `PUT`    | `/trips/{tripId}/messages/{messageId}`| 更新留言 | JWT  |
| `DELETE` | `/trips/{tripId}/messages/{messageId}`| 刪除留言 | JWT  |

### 投票 (Polls)

| Method   | Path                                                       | 說明     | 認證 |
| :------- | :--------------------------------------------------------- | :------- | :--- |
| `GET`    | `/trips/{tripId}/polls`                                    | 投票列表 | JWT  |
| `POST`   | `/trips/{tripId}/polls`                                    | 建立投票 | JWT  |
| `GET`    | `/trips/{tripId}/polls/{pollId}`                           | 投票詳情 | JWT  |
| `DELETE` | `/trips/{tripId}/polls/{pollId}`                           | 刪除投票 | JWT  |
| `POST`   | `/trips/{tripId}/polls/{pollId}/options`                   | 新增選項 | JWT  |
| `POST`   | `/trips/{tripId}/polls/{pollId}/options/{optionId}/vote`   | 投票     | JWT  |

### 個人裝備庫 / 食物庫 (Libraries)

| Method   | Path                       | 說明           | 認證 |
| :------- | :------------------------- | :------------- | :--- |
| `GET`    | `/gear-library`            | 個人裝備庫     | JWT  |
| `POST`   | `/gear-library`            | 新增裝備庫項目 | JWT  |
| `GET`    | `/gear-library/{itemId}`   | 裝備庫項目詳情 | JWT  |
| `PUT`    | `/gear-library/{itemId}`   | 更新裝備庫項目 | JWT  |
| `DELETE` | `/gear-library/{itemId}`   | 刪除裝備庫項目 | JWT  |
| `GET`    | `/meal-library`            | 個人食物庫     | JWT  |
| `POST`   | `/meal-library`            | 新增食物庫項目 | JWT  |
| `GET`    | `/meal-library/{itemId}`   | 食物庫項目詳情 | JWT  |
| `PUT`    | `/meal-library/{itemId}`   | 更新食物庫項目 | JWT  |
| `DELETE` | `/meal-library/{itemId}`   | 刪除食物庫項目 | JWT  |

### 雲端裝備組合 (Gear Sets)

| Method   | Path               | 說明                                  | 認證 |
| :------- | :----------------- | :------------------------------------ | :--- |
| `GET`    | `/gear-sets`       | 搜尋/列出雲端裝備組合 (支援 `my_uploaded`) | JWT  |
| `POST`   | `/gear-sets`       | 上傳裝備組合                          | JWT  |
| `GET`    | `/gear-sets/{id}`  | 裝備組合詳情/下載 (protected 需 `key`)| JWT  |
| `DELETE` | `/gear-sets/{id}`  | 刪除裝備組合                          | JWT  |

### 收藏 (Favorites)

| Method   | Path                    | 說明         | 認證 |
| :------- | :---------------------- | :----------- | :--- |
| `GET`    | `/favorites`            | 收藏列表     | JWT  |
| `POST`   | `/favorites`            | 新增收藏     | JWT  |
| `PUT`    | `/favorites/batch`      | 批次更新收藏 | JWT  |
| `DELETE` | `/favorites/{targetId}` | 移除收藏     | JWT  |

### 揪團活動 (Group Events)

| Method   | Path                                   | 說明                  | 認證 |
| :------- | :------------------------------------- | :-------------------- | :--- |
| `GET`    | `/group-events`                        | 揪團列表 (分頁/搜尋)  | 無   |
| `GET`    | `/group-events/my`                     | 我的活動 (host/apply/like) | JWT |
| `POST`   | `/group-events`                        | 建立揪團              | JWT  |
| `GET`    | `/group-events/{id}`                   | 揪團詳情              | 無   |
| `PATCH`  | `/group-events/{id}`                   | 更新揪團              | JWT  |
| `DELETE` | `/group-events/{id}`                   | 刪除揪團              | JWT  |
| `POST`   | `/group-events/{id}/apply`             | 報名揪團              | JWT  |
| `PATCH`  | `/group-events/{id}/trip-link`         | 連結/取消連結行程     | JWT  |
| `POST`   | `/group-events/{id}/trip-snapshot`     | 更新行程快照          | JWT  |
| `GET`    | `/group-events/{id}/applications`      | 報名列表              | JWT  |
| `PATCH`  | `/group-events/applications/{app_id}`  | 審核報名              | JWT  |
| `GET`    | `/group-events/{id}/comments`          | 留言列表              | 無   |
| `POST`   | `/group-events/{id}/comments`          | 新增留言              | JWT  |
| `DELETE` | `/group-events/comments/{comment_id}`  | 刪除留言              | JWT  |
| `POST`   | `/group-events/{id}/like`              | 按讚/取消讚           | JWT  |

### 天氣 (Weather)

| Method | Path                         | 說明         | 認證 |
| :----- | :--------------------------- | :----------- | :--- |
| `GET`  | `/weather/hiking`            | 登山氣象資料 | 無   |
| `GET`  | `/weather/hiking/{location}` | 特定地點氣象 | 無   |

---

互動式 API 文件：`GET /docs` (Scalar API Reference UI)

OpenAPI Spec：`GET /openapi.json`

> [!IMPORTANT]
> 既有的批次取代端點 (`/trips/{id}/gear/batch`、`/meals/batch`、`/gear-library/batch`、`/meal-library/batch`) 已不存在於目前的 OpenAPI 規格；裝備/食物/庫存的批次同步改由各別 CRUD 端點搭配前端 `SyncService` 完成。僅保留 `PUT /favorites/batch`。

---
