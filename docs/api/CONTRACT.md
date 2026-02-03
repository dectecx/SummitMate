# API Contract

## 1. 概述 (Overview)

本文件定義 App (Flutter) 與 Backend (GAS) 之間的通訊協定。
所有請求皆透過 HTTP POST 發送至單一 GAS Web App URL，並藉由 payload 中的 `action` 參數區分路由。

### 1.1 基礎格式 (Base Format)

**Request Payload:**

| Field  | Type   | Required | Description                  |
| :----- | :----- | :------- | :--------------------------- |
| action | String | Yes      | 路由指令 (e.g., `trip_list`) |
| data   | Object | Yes      | 實際請求參數 (依各 API 定義) |
| token  | String | No       | Auth Token (若需驗證)        |

**Response Payload:**

| Field   | Type   | Description              |
| :------ | :----- | :----------------------- |
| status  | String | `success` 或 `error`     |
| code    | String | 狀態碼 (0000 為成功)     |
| message | String | 錯誤訊息或提示           |
| data    | Object | 回傳資料 (依各 API 定義) |

### 1.2 通用 Audit 欄位

所有數據資源回應均包含以下稽核欄位：

| Field      | Type   | Description      |
| :--------- | :----- | :--------------- |
| created_at | String | ISO8601 建立時間 |
| created_by | String | 建立者 User ID   |
| updated_at | String | ISO8601 更新時間 |
| updated_by | String | 更新者 User ID   |

---

## 2. 行程模組 (Trips)

### 2.1 取得行程列表 (trip_list)

**Request (`data`):**
_無參數_

**Response (`data`):**

| Field | Type        | Description  |
| :---- | :---------- | :----------- |
| trips | Array[Trip] | 行程物件列表 |

### 2.2 建立行程 (trip_create)

**Request (`data`):**

| Field       | Type          | Required | Description                   |
| :---------- | :------------ | :------- | :---------------------------- |
| name        | String        | Yes      | 行程名稱                      |
| start_date  | String        | No       | ISO8601 Date                  |
| end_date    | String        | No       | ISO8601 Date                  |
| description | String        | No       |                               |
| members     | Array[String] | No       | 初始成員 ID 列表 (Deprecated) |

**Response (`data`):**

| Field | Type   | Description   |
| :---- | :----- | :------------ |
| id    | String | 新建之行程 ID |

### 2.3 更新行程 (trip_update)

**Request (`data`):**

| Field | Type   | Required | Description                     |
| :---- | :----- | :------- | :------------------------------ |
| id    | String | Yes      | 目標行程 ID                     |
| ...   | ...    | No       | 其他 Trip 欄位 (Partial Update) |

**Response (`data`):** `null`

### 2.4 刪除行程 (trip_delete)

**Request (`data`):**

| Field | Type   | Required | Description |
| :---- | :----- | :------- | :---------- |
| id    | String | Yes      | 行程 ID     |

**Response (`data`):** `null`

### 2.5 設定當前行程 (trip_set_active)

**Request (`data`):**

| Field | Type   | Required | Description      |
| :---- | :----- | :------- | :--------------- |
| id    | String | Yes      | 行程 ID          |
| value | Bool   | Yes      | true: Set Active |

**Response (`data`):** `null`

### 2.6 行程同步 (trip_sync)

**Request (`data`):**

| Field     | Type                 | Required | Description  |
| :-------- | :------------------- | :------- | :----------- |
| trip_id   | String               | Yes      | 行程 ID      |
| trip      | Trip                 | Yes      | 行程基本資料 |
| itinerary | Array[ItineraryItem] | No       | 行程節點     |
| gear      | Array[GearItem]      | No       | 裝備         |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | Trip ID     |

---

## 3. 行程成員模組 (Trip Members)

### 3.1 取得成員列表 (trip_get_members)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| trip_id | String | Yes      | 行程 ID     |

**Response (`data`):**

| Field   | Type          | Description |
| :------ | :------------ | :---------- |
| members | Array[Member] | 成員列表    |

### 3.2 搜尋使用者 (trip_search_user_by_email / trip_search_user_by_id)

**Request (`data`):**

| Field | Type   | Required | Description   |
| :---- | :----- | :------- | :------------ |
| email | String | Yes/No   | 依 Email 搜尋 |
| id    | String | Yes/No   | 依 ID 搜尋    |

**Response (`data`):**

| Field | Type | Description |
| :---- | :--- | :---------- |
| user  | User | 使用者簡檔  |

### 3.3 新增成員 (trip_add_member_by_email / trip_add_member_by_id)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| trip_id   | String | Yes      |             |
| email/id  | String | Yes      |             |
| role_code | String | No       | 預設 member |

**Response (`data`):**

| Field  | Type   | Description    |
| :----- | :----- | :------------- |
| member | Member | 新增的成員物件 |

### 3.4 移除成員 (trip_remove_member)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| trip_id | String | Yes      |             |
| user_id | String | Yes      |             |

**Response (`data`):** `null`

### 3.5 更新成員角色 (trip_update_member_role)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| trip_id   | String | Yes      |             |
| user_id   | String | Yes      |             |
| role_code | String | Yes      |             |

**Response (`data`):** `null`

---

## 4. 行程細節模組 (Itinerary)

### 4.1 取得行程節點 (itinerary_list)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| trip_id | String | Yes      | 行程 ID     |

**Response (`data`):**

| Field     | Type                 | Description |
| :-------- | :------------------- | :---------- |
| itinerary | Array[ItineraryItem] | 節點列表    |

### 4.2 更新行程節點 (itinerary_update)

**Request (`data`):**

| Field   | Type                 | Required | Description                  |
| :------ | :------------------- | :------- | :--------------------------- |
| trip_id | String               | Yes      | 行程 ID                      |
| data    | Array[ItineraryItem] | Yes      | 完整的節點列表 (Replace All) |

**Response (`data`):** `null`

### 4.3 取得完整行程資料 (trip_get_full)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| trip_id | String | Yes      | 行程 ID     |

**Response (`data`):**

| Field     | Type                 | Description |
| :-------- | :------------------- | :---------- |
| trip      | Trip                 | 行程資訊    |
| members   | Array[Member]        | 成員        |
| itinerary | Array[ItineraryItem] | 節點        |

---

## 5. 留言板模組 (Messages)

### 5.1 取得留言 (message_list)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| trip_id | String | Yes      | 行程 ID     |

**Response (`data`):**

| Field    | Type           | Description |
| :------- | :------------- | :---------- |
| messages | Array[Message] | 留言列表    |

### 5.2 建立留言 (message_create)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| trip_id   | String | Yes      | 行程 ID     |
| content   | String | Yes      | 內容        |
| parent_id | String | No       | 回覆留言 ID |
| category  | String | No       |             |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | 新留言 ID   |

### 5.3 批次建立留言 (message_create_batch)

**Request (`data`):**

| Field    | Type           | Required | Description |
| :------- | :------------- | :------- | :---------- |
| messages | Array[Message] | Yes      |             |

**Response (`data`):**

| Field | Type          | Description |
| :---- | :------------ | :---------- |
| ids   | Array[String] | 新留言 ID   |

### 5.4 刪除留言 (message_delete)

**Request (`data`):**

| Field      | Type   | Required | Description |
| :--------- | :----- | :------- | :---------- |
| message_id | String | Yes      |             |

**Response (`data`):** `null`

---

## 6. 投票模組 (Polls)

### 6.1 取得投票列表 (poll_list)

**Request (`data`):**
_無_ (Future: `trip_id`)

**Response (`data`):**

| Field | Type        | Description  |
| :---- | :---------- | :----------- |
| polls | Array[Poll] | 投票物件列表 |

**Poll 物件欄位：**

| Field                | Type          | Description           |
| :------------------- | :------------ | :-------------------- |
| id                   | String        | PK                    |
| title                | String        | 標題                  |
| description          | String        | 描述                  |
| creator_id           | String        | 建立者 ID             |
| deadline             | String        | ISO8601 截止時間      |
| is_allow_add_option  | Boolean       | 是否允許新增選項      |
| allow_multiple_votes | Boolean       | 是否允許複選          |
| status               | String        | `active` 或 `ended`   |
| options              | Array[Option] | 選項列表              |
| my_votes             | Array[String] | 當前使用者已投選項 ID |
| total_votes          | Number        | 總票數                |

### 6.2 建立投票 (poll_create)

**Request (`data`):**

| Field | Type   | Required | Description    |
| :---- | :----- | :------- | :------------- |
| title | String | Yes      |                |
| ...   | ...    | ...      | 參考 DB Schema |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | Poll ID     |

### 6.3 投票 (poll_vote)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| poll_id   | String | Yes      |             |
| option_id | String | Yes      |             |

**Response (`data`):** `null`

### 6.4 新增選項 (poll_add_option)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| poll_id | String | Yes      |             |
| text    | String | Yes      |             |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | Option ID   |

### 6.5 刪除選項 (poll_delete_option)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| option_id | String | Yes      |             |

**Response (`data`):** `null`

### 6.6 關閉/刪除投票 (poll_close / poll_delete)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| poll_id | String | Yes      |             |

**Response (`data`):** `null`

---

## 7. 裝備模組 (Gear)

### 7.1 裝備組合列表 (gear_set_list)

**Request (`data`):**
_無_

**Response (`data`):**

| Field | Type           | Description  |
| :---- | :------------- | :----------- |
| sets  | Array[GearSet] | Summary List |

### 7.2 下載裝備組合 (gear_set_download / gear_set_get)

**Request (`data`):**

| Field | Type   | Required | Description |
| :---- | :----- | :------- | :---------- |
| key   | String | Yes      | 分享碼      |

**Response (`data`):**

| Field | Type    | Description |
| :---- | :------ | :---------- |
| set   | GearSet | 完整內容    |

### 7.3 上傳裝備組合 (gear_set_upload)

**Request (`data`):**

| Field | Type    | Required | Description |
| :---- | :------ | :------- | :---------- |
| set   | GearSet | Yes      |             |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String |             |
| key   | String | 分享碼      |

### 7.4 刪除裝備組合 (gear_set_delete)

**Request (`data`):**

| Field | Type   | Required | Description |
| :---- | :----- | :------- | :---------- |
| id    | String | Yes      |             |
| key   | String | Yes      |             |

**Response (`data`):** `null`

### 7.5 個人裝備庫 (gear_library_upload / gear_library_download)

**Request (`data`):**

| Field | Type  | Required | Description |
| :---- | :---- | :------- | :---------- |
| items | Array | Yes      |             |

**Response (`data`):**

| Field | Type  | Description |
| :---- | :---- | :---------- |
| items | Array |             |

---

## 8. 揪團模組 (Group Events)

> [!NOTE]
> 僅限線上模式使用。訪客僅能查看列表，需登入才能操作。

### 8.1 取得揪團列表 (group_event_list)

**Request (`data`):**

| Field  | Type   | Required | Description                   |
| :----- | :----- | :------- | :---------------------------- |
| filter | String | No       | `all`, `popular`, `upcoming`  |
| status | String | No       | `open`, `closed` (預設: open) |

**Response (`data`):**

| Field  | Type              | Description |
| :----- | :---------------- | :---------- |
| events | Array[GroupEvent] | 揪團列表    |

### 8.2 取得揪團詳情 (group_event_get)

**Request (`data`):**

| Field    | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| event_id | String | Yes      |             |

**Response (`data`):**

| Field | Type       | Description |
| :---- | :--------- | :---------- |
| event | GroupEvent | 揪團詳情    |

### 8.3 建立揪團 (group_event_create)

**Request (`data`):**

| Field             | Type    | Required | Description                   |
| :---------------- | :------ | :------- | :---------------------------- |
| title             | String  | Yes      |                               |
| description       | String  | No       |                               |
| location          | String  | No       |                               |
| start_date        | String  | Yes      | ISO8601                       |
| end_date          | String  | No       | ISO8601                       |
| max_members       | Number  | Yes      |                               |
| approval_required | Boolean | No       | Default: false                |
| private_message   | String  | No       | 報名成功訊息 (審核通過後顯示) |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | Event ID    |

### 8.4 更新揪團 (group_event_update)

**Request (`data`):**

| Field    | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| event_id | String | Yes      |             |
| ...      | ...    | No       | 同 create   |

**Response (`data`):** `null`

### 8.5 刪除/關閉揪團 (group_event_close / group_event_delete)

**Request (`data`):**

| Field    | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| event_id | String | Yes      |             |

**Response (`data`):** `null`

### 8.6 報名揪團 (group_event_apply)

**Request (`data`):**

| Field    | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| event_id | String | Yes      |             |
| message  | String | No       | 報名留言    |

**Response (`data`):**

| Field | Type   | Description    |
| :---- | :----- | :------------- |
| id    | String | Application ID |

### 8.7 審核報名 (group_event_review_application)

**Request (`data`):**

| Field          | Type   | Required | Description         |
| :------------- | :----- | :------- | :------------------ |
| application_id | String | Yes      |                     |
| action         | String | Yes      | `approve`, `reject` |

**Response (`data`):** `null`

### 8.8 我的揪團 (group_event_my)

**Request (`data`):**

| Field | Type   | Required | Description                   |
| :---- | :----- | :------- | :---------------------------- |
| type  | String | Yes      | `created`, `applied`, `liked` |

**Response (`data`):**

| Field  | Type              | Description |
| :----- | :---------------- | :---------- |
| events | Array[GroupEvent] |             |

### 8.9 喜歡揪團 (group_event_like) - TODO

### 8.10 留言 (group_event_comment) - TODO

---

## 9. 會員模組 (Auth)

### 9.1 註冊 (auth_register)

**Request (`data`):**

| Field    | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| email    | String | Yes      |             |
| password | String | Yes      |             |
| name     | String | Yes      |             |

**Response (`data`):**

| Field | Type   | Description |
| :---- | :----- | :---------- |
| id    | String | User ID     |

### 9.2 登入 (auth_login)

**Request (`data`):**

| Field    | Type   | Required | Description                 |
| :------- | :----- | :------- | :-------------------------- |
| email    | String | Yes      |                             |
| password | String | Yes      | Plain text (Hash on server) |

**Response (`data`):**

| Field | Type        | Description   |
| :---- | :---------- | :------------ |
| token | String      | Session Token |
| user  | UserProfile | 使用者資料    |

### 9.3 驗證 Token (auth_validate / auth_refresh_token)

**Request (`data`):**

| Field | Type   | Required | Description |
| :---- | :----- | :------- | :---------- |
| token | String | Yes      |             |

**Response (`data`):** `User` or `New Token`

### 9.4 更新個人資料 (auth_update_profile)

**Request (`data`):**

| Field | Type        | Required | Description |
| :---- | :---------- | :------- | :---------- |
| user  | UserProfile | Yes      | Partial     |

**Response (`data`):** `null`

### 9.5 角色管理 (auth_get_roles / auth_assign_role)

**Request (`data`):**

| Field   | Type   | Required | Description |
| :------ | :----- | :------- | :---------- |
| user_id | String | Yes      | For assign  |
| role_id | String | Yes      | For assign  |

---

## 10. 系統模組 (System)

### 10.1 上傳日誌 (log_upload)

**Request (`data`):**

| Field | Type       | Required | Description |
| :---- | :--------- | :------- | :---------- |
| logs  | Array[Log] | Yes      |             |

### 10.2 心跳檢測 (system_heartbeat)

**Request (`data`):**

| Field     | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| user_id   | String | Yes      |             |
| view      | String | No       |             |
| timestamp | String | Yes      |             |

### 10.3 氣象資訊 (weather_get)

**Request (`data`):**
_無參數_ (GET 請求)

**Response (`data`):**

| Field   | Type           | Description                   |
| :------ | :------------- | :---------------------------- |
| weather | Array[Weather] | 登山氣象預報資料 (中央氣象署) |
