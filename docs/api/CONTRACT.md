# API Contract

## Go Backend RESTful API

後端已遷移至 Go (Chi + PostgreSQL)，採用 OpenAPI 3.0 規格定義。所有端點以 `/api/v1` 為前綴，使用標準 HTTP Method 與 JSON 格式。

### 認證機制

需認證的端點必須在 Request Header 中帶入 JWT：

```
Authorization: Bearer <access_token>
```

### API 路由總覽

| Method   | Path                                              | 說明           | 認證 |
| :------- | :------------------------------------------------ | :------------- | :--- |
| `GET`    | `/health`                                         | 健康檢查       | 無   |
| `POST`   | `/auth/register`                                  | 註冊           | 無   |
| `POST`   | `/auth/login`                                     | 登入           | 無   |
| `POST`   | `/auth/refresh`                                   | 刷新 Token     | 無   |
| `POST`   | `/auth/verify-email`                              | 驗證信箱       | 無   |
| `POST`   | `/auth/resend-verification`                       | 重發驗證碼     | 無   |
| `GET`    | `/auth/me`                                        | 取得當前使用者 | JWT  |
| `PUT`    | `/auth/me`                                        | 更新個人資料   | JWT  |
| `DELETE` | `/auth/me`                                        | 停用帳號       | JWT  |
| `GET`    | `/trips`                                          | 行程列表       | JWT  |
| `POST`   | `/trips`                                          | 建立行程       | JWT  |
| `GET`    | `/trips/{id}`                                     | 行程詳情       | JWT  |
| `PUT`    | `/trips/{id}`                                     | 更新行程       | JWT  |
| `DELETE` | `/trips/{id}`                                     | 刪除行程       | JWT  |
| `GET`    | `/trips/{id}/members`                             | 成員列表       | JWT  |
| `POST`   | `/trips/{id}/members`                             | 新增成員       | JWT  |
| `DELETE` | `/trips/{id}/members/{userId}`                    | 移除成員       | JWT  |
| `GET`    | `/trips/{id}/itinerary`                           | 行程節點列表   | JWT  |
| `POST`   | `/trips/{id}/itinerary`                           | 新增節點       | JWT  |
| `PUT`    | `/trips/{id}/itinerary/{itemId}`                  | 更新節點       | JWT  |
| `DELETE` | `/trips/{id}/itinerary/{itemId}`                  | 刪除節點       | JWT  |
| `GET`    | `/trips/{id}/gear`                                | 行程裝備列表   | JWT  |
| `POST`   | `/trips/{id}/gear`                                | 新增裝備       | JWT  |
| `PUT`    | `/trips/{id}/gear/{itemId}`                       | 更新裝備       | JWT  |
| `DELETE` | `/trips/{id}/gear/{itemId}`                       | 刪除裝備       | JWT  |
| `PUT`    | `/trips/{id}/gear/batch`                          | 批次取代裝備   | JWT  |
| `GET`    | `/trips/{id}/meals`                               | 行程食物列表   | JWT  |
| `POST`   | `/trips/{id}/meals`                               | 新增食物       | JWT  |
| `PUT`    | `/trips/{id}/meals/{itemId}`                      | 更新食物       | JWT  |
| `DELETE` | `/trips/{id}/meals/{itemId}`                      | 刪除食物       | JWT  |
| `PUT`    | `/trips/{id}/meals/batch`                         | 批次取代食物   | JWT  |
| `GET`    | `/trips/{id}/messages`                            | 留言列表       | JWT  |
| `POST`   | `/trips/{id}/messages`                            | 新增留言       | JWT  |
| `PUT`    | `/trips/{id}/messages/{msgId}`                    | 更新留言       | JWT  |
| `DELETE` | `/trips/{id}/messages/{msgId}`                    | 刪除留言       | JWT  |
| `GET`    | `/trips/{id}/polls`                               | 投票列表       | JWT  |
| `POST`   | `/trips/{id}/polls`                               | 建立投票       | JWT  |
| `GET`    | `/trips/{id}/polls/{pollId}`                      | 投票詳情       | JWT  |
| `DELETE` | `/trips/{id}/polls/{pollId}`                      | 刪除投票       | JWT  |
| `POST`   | `/trips/{id}/polls/{pollId}/options`              | 新增選項       | JWT  |
| `POST`   | `/trips/{id}/polls/{pollId}/options/{optId}/vote` | 投票           | JWT  |
| `GET`    | `/gear-library`                                   | 個人裝備庫     | JWT  |
| `POST`   | `/gear-library`                                   | 新增裝備庫項目 | JWT  |
| `GET`    | `/gear-library/{id}`                              | 裝備庫項目詳情 | JWT  |
| `PUT`    | `/gear-library/{id}`                              | 更新裝備庫項目 | JWT  |
| `DELETE` | `/gear-library/{id}`                              | 刪除裝備庫項目 | JWT  |
| `PUT`    | `/gear-library/batch`                             | 批次取代裝備庫 | JWT  |
| `GET`    | `/meal-library`                                   | 個人食物庫     | JWT  |
| `POST`   | `/meal-library`                                   | 新增食物庫項目 | JWT  |
| `GET`    | `/meal-library/{id}`                              | 食物庫項目詳情 | JWT  |
| `PUT`    | `/meal-library/{id}`                              | 更新食物庫項目 | JWT  |
| `DELETE` | `/meal-library/{id}`                              | 刪除食物庫項目 | JWT  |
| `PUT`    | `/meal-library/batch`                             | 批次取代食物庫 | JWT  |
| `GET`    | `/favorites`                                      | 收藏列表       | JWT  |
| `POST`   | `/favorites`                                      | 新增收藏       | JWT  |
| `DELETE` | `/favorites/{targetId}`                           | 移除收藏       | JWT  |
| `PUT`    | `/favorites/batch`                                | 批次更新收藏   | JWT  |
| `GET`    | `/group-events`                                   | 揪團列表       | 無   |
| `POST`   | `/group-events`                                   | 建立揪團       | JWT  |
| `GET`    | `/group-events/{id}`                              | 揪團詳情       | 無   |
| `PATCH`  | `/group-events/{id}`                              | 更新揪團       | JWT  |
| `DELETE` | `/group-events/{id}`                              | 刪除揪團       | JWT  |
| `POST`   | `/group-events/{id}/apply`                        | 報名揪團       | JWT  |
| `GET`    | `/group-events/{id}/applications`                 | 報名列表       | JWT  |
| `PATCH`  | `/group-events/applications/{appId}`              | 審核報名       | JWT  |
| `GET`    | `/group-events/{id}/comments`                     | 留言列表       | 無   |
| `POST`   | `/group-events/{id}/comments`                     | 新增留言       | JWT  |
| `DELETE` | `/group-events/comments/{commentId}`              | 刪除留言       | JWT  |
| `POST`   | `/group-events/{id}/like`                         | 按讚/取消讚    | JWT  |
| `GET`    | `/weather/hiking`                                 | 登山氣象資料   | 無   |
| `GET`    | `/weather/hiking/{location}`                      | 特定地點氣象   | 無   |
| `POST`   | `/logs`                                           | 上傳 App 日誌  | 無   |
| `POST`   | `/system/heartbeat`                               | 心跳與統計同步 | JWT  |

互動式 API 文件：`GET /docs` (Scalar API Reference UI)

OpenAPI Spec：`GET /openapi.json`

---
