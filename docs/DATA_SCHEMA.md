# 資料規格文件 (Data Schema)

這份文件詳細定義了 SummitMate 應用程式的本地資料庫 (Hive) 與雲端資料庫 (Google Sheets) 的資料結構。

## 1. 本地資料庫設計 (Hive Schema)

本專案使用 [Hive](https://docs.hivedb.dev/) 作為本地 NoSQL 資料庫。
Hive 的 TypeId 必須全域唯一。

### Box: `settings` (TypeId: 0)

全域設定，通常為單例 (Singleton) 存儲。

| Field         | Type        | Key | Default | Description               |
| :------------ | :---------- | :-- | :------ | :------------------------ |
| username      | `String`    | 0   | `''`    | 使用者暱稱 (用於留言識別) |
| lastSyncTime  | `DateTime?` | 1   | `null`  | 上次同步時間              |
| avatar        | `String`    | 2   | `'🐻'`  | 使用者頭像 (Emoji)        |
| isOfflineMode | `bool`      | 3   | `false` | 離線模式開關              |

### Box: `itinerary` (TypeId: 1)

行程節點，支援雲端下載與本地修改。

| Field       | Type        | Key | Default | Description                     |
| :---------- | :---------- | :-- | :------ | :------------------------------ |
| uuid        | `String`    | 0   | -       | **PK** 節點唯一識別碼           |
| tripId      | `String`    | 1   | -       | **FK** 關聯的行程 ID            |
| day         | `String`    | 2   | `''`    | 行程天數 (e.g., "D0", "D1")     |
| name        | `String`    | 3   | `''`    | 地標名稱                        |
| estTime     | `String`    | 4   | `''`    | 預計時間 (HH:mm) - Display Only |
| actualTime  | `DateTime?` | 5   | `null`  | 實際打卡時間                    |
| altitude    | `int`       | 6   | `0`     | 海拔 (m)                        |
| distance    | `double`    | 7   | `0.0`   | 里程 (km)                       |
| note        | `String`    | 8   | `''`    | 備註                            |
| imageAsset  | `String?`   | 9   | `null`  | 對應 Assets 圖片檔名            |
| isCheckedIn | `bool`      | 10  | `false` | 是否已打卡                      |
| checkedInAt | `DateTime?` | 11  | `null`  | 打卡時間                        |
| createdBy   | `String?`   | 12  | `null`  | 建立者 ID                       |
| updatedBy   | `String?`   | 13  | `null`  | 更新者 ID                       |

### Box: `messages` (TypeId: 2)

留言板資料，支援雙向同步。

| Field     | Type       | Key | Default | Description                      |
| :-------- | :--------- | :-- | :------ | :------------------------------- |
| uuid      | `String`   | 0   | -       | **PK** 留言唯一識別碼            |
| tripId    | `String?`  | 1   | `null`  | **FK** 關聯行程 ID (null = 全域) |
| parentId  | `String?`  | 2   | `null`  | **FK** 父留言 ID (Thread)        |
| user      | `String`   | 3   | `''`    | 發文者暱稱                       |
| category  | `String`   | 4   | `''`    | 分類 (Gear, Plan, Misc)          |
| content   | `String`   | 5   | `''`    | 留言內容                         |
| timestamp | `DateTime` | 6   | `now`   | 發文時間                         |
| avatar    | `String`   | 7   | `'🐻'`  | 使用者頭像                       |

### Box: `gear` (TypeId: 3)

個人裝備清單 (與 Trip 關聯)。

| Field         | Type      | Key | Default   | Description                     |
| :------------ | :-------- | :-- | :-------- | :------------------------------ |
| uuid          | `String`  | 0   | -         | **PK** 裝備項目 ID              |
| tripId        | `String?` | 1   | `null`    | **FK** 關聯行程 ID              |
| libraryItemId | `String?` | 2   | `null`    | **FK** 關聯裝備庫 ID (連結模式) |
| name          | `String`  | 3   | `''`      | 裝備名稱 (快取或獨立)           |
| weight        | `double`  | 4   | `0.0`     | 重量 (g)                        |
| category      | `String`  | 5   | `'Other'` | 分類 (Sleep, Cook, Wear, Other) |
| isChecked     | `bool`    | 6   | `false`   | 是否已打包                      |
| orderIndex    | `int?`    | 7   | `null`    | 排序索引                        |
| quantity      | `int`     | 8   | `1`       | 數量 (v0.0.6 新增)              |

### Box: `weather` (TypeId: 4)

氣象資料快取。

| Field               | Type                  | Key | Description                |
| :------------------ | :-------------------- | :-- | :------------------------- |
| temperature         | `double`              | 0   | 目前氣溫 (°C)              |
| humidity            | `double`              | 1   | 相對濕度 (%)               |
| rainProbability     | `int`                 | 2   | 降雨機率 (%)               |
| windSpeed           | `double`              | 3   | 風速 (m/s)                 |
| condition           | `String`              | 4   | 天氣現象描述               |
| sunrise             | `DateTime`            | 5   | 日出時間                   |
| sunset              | `DateTime`            | 6   | 日沒時間                   |
| timestamp           | `DateTime`            | 7   | 資料更新時間               |
| locationName        | `String`              | 8   | 地點名稱                   |
| dailyForecasts      | `List<DailyForecast>` | 9   | 未來 7 天預報              |
| apparentTemperature | `double?`             | 10  | 體感溫度 (v0.0.6 新增)     |
| issueTime           | `DateTime?`           | 11  | 官方發布時間 (v0.0.6 新增) |

### Type: `DailyForecast` (TypeId: 5)

氣象預報子結構 (嵌入在 WeatherData 中)。

| Field           | Type       | Key | Description |
| :-------------- | :--------- | :-- | :---------- |
| date            | `DateTime` | 0   | 日期        |
| dayCondition    | `String`   | 1   | 白天天氣    |
| nightCondition  | `String`   | 2   | 晚上天氣    |
| maxTemp         | `double`   | 3   | 最高溫      |
| minTemp         | `double`   | 4   | 最低溫      |
| rainProbability | `int`      | 5   | 降雨機率    |
| maxApparentTemp | `double?`  | 6   | 最高體感溫  |
| minApparentTemp | `double?`  | 7   | 最低體感溫  |

### Box: `polls` (TypeId: 6)

投票活動資料。

| Field              | Type               | Key | Default      | Description               |
| :----------------- | :----------------- | :-- | :----------- | :------------------------ |
| id                 | `String`           | 0   | -            | **PK** 投票 ID            |
| title              | `String`           | 1   | -            | 標題                      |
| description        | `String`           | 2   | `''`         | 描述                      |
| creatorId          | `String`           | 3   | -            | 建立者 ID                 |
| createdAt          | `DateTime`         | 4   | -            | 建立時間                  |
| deadline           | `DateTime?`        | 5   | `null`       | 截止時間                  |
| isAllowAddOption   | `bool`             | 6   | `false`      | 允許新增選項              |
| maxOptionLimit     | `int`              | 7   | `20`         | 選項上限                  |
| allowMultipleVotes | `bool`             | 8   | `false`      | 允許多選                  |
| resultDisplayType  | `String`           | 9   | `'realtime'` | 結果顯示 (realtime/blind) |
| status             | `String`           | 10  | `'active'`   | 狀態 (active/ended)       |
| options            | `List<PollOption>` | 11  | `[]`         | 選項列表                  |
| myVotes            | `List<String>`     | 12  | `[]`         | 我的投票紀錄 (Option IDs) |
| totalVotes         | `int`              | 13  | `0`          | 總票數                    |

### Type: `PollOption` (TypeId: 7)

投票選項子結構。

| Field     | Type        | Key | Default | Description    |
| :-------- | :---------- | :-- | :------ | :------------- |
| id        | `String`    | 0   | -       | **PK** 選項 ID |
| pollId    | `String`    | 1   | -       | **FK** 投票 ID |
| text      | `String`    | 2   | -       | 選項文字       |
| creatorId | `String`    | 3   | -       | 建立者 ID      |
| voteCount | `int`       | 4   | `0`     | 得票數         |
| voters    | `List<Map>` | 5   | `[]`    | 投票者詳細資料 |

### Box: `trips` (TypeId: 10)

行程管理 (多行程支援)。

| Field       | Type        | Key | Default | Description    |
| :---------- | :---------- | :-- | :------ | :------------- |
| id          | `String`    | 0   | -       | **PK** 行程 ID |
| name        | `String`    | 1   | `''`    | 行程名稱       |
| startDate   | `DateTime`  | 2   | -       | 開始日期       |
| endDate     | `DateTime?` | 3   | `null`  | 結束日期       |
| description | `String?`   | 4   | `null`  | 描述           |
| coverImage  | `String?`   | 5   | `null`  | 封面圖片       |
| isActive    | `bool`         | 6   | `false` | 是否為當前行程 |
| createdAt   | `DateTime`     | 7   | `now`   | 建立時間       |
| dayNames    | `List<String>` | 8   | `[]`    | 行程天數列表   |
| createdBy   | `String?`      | 9   | `null`  | 建立者 ID      |
| updatedBy   | `String?`      | 10  | `null`  | 更新者 ID      |

### Box: `gearLibrary` (TypeId: 11)

個人裝備庫 (Master Data)。

| Field      | Type        | Key | Default   | Description   |
| :--------- | :---------- | :-- | :-------- | :------------ |
| uuid       | `String`    | 0   | -         | **PK** 識別碼 |
| name       | `String`    | 1   | `''`      | 名稱          |
| weight     | `double`    | 2   | `0.0`     | 重量 (g)      |
| category   | `String`    | 3   | `'Other'` | 分類          |
| notes      | `String?`   | 4   | `null`    | 備註          |
| createdAt  | `DateTime`  | 5   | `now`     | 建立時間      |
| updatedAt  | `DateTime?` | 6   | `null`    | 更新時間      |
| isArchived | `bool`      | 7   | `false`   | 是否封存      |

---

## 2. Google Sheets 資料結構 (Cloud Schema)

雲端資料庫使用 Google Sheets 模擬，欄位順序必須嚴格遵守。
欄位順序原則: `PK` (主鍵) → `FK` (外鍵) → `Data Fields`。

### Sheet: `Users` (會員資料)

| Column Index | Field               | Description                |
| :----------- | :------------------ | :------------------------- |
| A            | uuid                | **PK** 會員 ID             |
| B            | email               | 電子郵件                   |
| C            | password_hash       | 密碼雜湊                   |
| D            | display_name        | 顯示名稱                   |
| E            | avatar              | 頭像 URL/Emoji             |
| F            | role                | 角色 (member/leader/admin) |
| G            | is_active           | 是否啟用 (TRUE/FALSE)      |
| H            | is_verified         | 是否驗證 Email             |
| I            | verification_code   | 驗證碼                     |
| J            | verification_expiry | 驗證碼過期時間             |
| K            | created_at          | 建立時間 (ISO8601)         |
| L            | updated_at          | 更新時間 (ISO8601)         |
| M            | last_login_at       | 最後登入時間               |

### Sheet: `Trips` (行程管理)

| Column Index | Field       | Description           |
| :----------- | :---------- | :-------------------- |
| A            | id          | **PK** 行程 ID        |
| B            | name        | 行程名稱              |
| C            | start_date  | 開始日期 (YYYY-MM-DD) |
| D            | end_date    | 結束日期 (YYYY-MM-DD) |
| E            | description | 描述                  |
| F            | cover_image | 封面圖片              |
| G            | is_active   | 是否啟用              |
| H            | created_at  | 建立時間              |
| I            | day_names   | 天數列表 (JSON)       |
| J            | created_by  | 建立者 ID             |
| K            | updated_by  | 更新者 ID             |

### Sheet: `Itinerary` (行程節點)

| Column Index | Field         | Description                  |
| :----------- | :------------ | :--------------------------- |
| A            | uuid          | **PK** 節點 ID               |
| B            | trip_id       | **FK** 行程 ID               |
| C            | day           | 天數 (D0, D1...)             |
| D            | name          | 地標名稱                     |
| E            | est_time      | 預計時間 (加 ' 前綴以防轉型) |
| F            | altitude      | 海拔                         |
| G            | distance      | 里程                         |
| H            | note          | 備註                         |
| I            | image_asset   | 圖片路徑                     |
| J            | is_checked_in | 是否打卡                     |
| K            | checked_in_at | 打卡時間                     |
| L            | created_by    | 建立者 ID                    |
| M            | updated_by    | 更新者 ID                    |

### Sheet: `Messages` (留言)

| Column Index | Field     | Description      |
| :----------- | :-------- | :--------------- |
| A            | uuid      | **PK** 留言 ID   |
| B            | trip_id   | **FK** 行程 ID   |
| C            | parent_id | **FK** 父留言 ID |
| D            | user      | 發文者           |
| E            | category  | 分類             |
| F            | content   | 內容             |
| G            | timestamp | 時間             |
| H            | avatar    | 頭像             |

### Sheet: `TripGear` (行程裝備)

| Column Index | Field      | Description    |
| :----------- | :--------- | :------------- |
| A            | uuid       | **PK** 裝備 ID |
| B            | trip_id    | **FK** 行程 ID |
| C            | name       | 名稱           |
| D            | weight     | 重量           |
| E            | category   | 分類           |
| F            | is_checked | 是否打包       |
| G            | quantity   | 數量           |

### Sheet: `GearLibrary` (個人裝備庫)

| Column Index | Field      | Description                           |
| :----------- | :--------- | :------------------------------------ |
| A            | uuid       | **PK** 裝備 ID                        |
| B            | owner_key  | **FK** 擁有者 ID (未來遷移至 user_id) |
| C            | name       | 名稱                                  |
| D            | weight     | 重量                                  |
| E            | category   | 分類                                  |
| F            | notes      | 備註                                  |
| G            | created_at | 建立時間                              |
| H            | updated_at | 更新時間                              |

### Sheet: `GearSets` (雲端裝備組合)

| Column Index | Field        | Description                       |
| :----------- | :----------- | :-------------------------------- |
| A            | uuid         | **PK** 組合 ID                    |
| B            | trip_id      | **FK** 來源行程 ID                |
| C            | title        | 標題                              |
| D            | author       | 作者                              |
| E            | visibility   | 可見性 (public/protected/private) |
| F            | key          | 存取金鑰 (4 位數)                 |
| G            | total_weight | 總重                              |
| H            | item_count   | 物品數                            |
| I            | uploaded_at  | 上傳時間                          |
| J            | items_json   | 裝備列表 (JSON)                   |
| K            | meals_json   | 糧食列表 (JSON)                   |

### Sheet: `Polls` (投票)

| Column Index | Field                | Description    |
| :----------- | :------------------- | :------------- |
| A            | poll_id              | **PK** 投票 ID |
| B            | title                | 標題           |
| C            | description          | 描述           |
| D            | creator_id           | 建立者         |
| E            | created_at           | 建立時間       |
| F            | deadline             | 截止時間       |
| G            | is_allow_add_option  | 允許加選項     |
| H            | max_option_limit     | 選項上限       |
| I            | allow_multiple_votes | 允許多選       |
| J            | result_display_type  | 顯示方式       |
| K            | status               | 狀態           |

### Sheet: `PollOptions` (投票選項)

| Column Index | Field      | Description    |
| :----------- | :--------- | :------------- |
| A            | option_id  | **PK** 選項 ID |
| B            | poll_id    | **FK** 投票 ID |
| C            | text       | 內容           |
| D            | creator_id | 建立者         |
| E            | created_at | 建立時間       |
| F            | image_url  | 圖片 (預留)    |

### Sheet: `PollVotes` (投票紀錄)

| Column Index | Field      | Description    |
| :----------- | :--------- | :------------- |
| A            | vote_id    | **PK** 票 ID   |
| B            | poll_id    | **FK** 投票 ID |
| C            | option_id  | **FK** 選項 ID |
| D            | user_id    | 投票者 ID      |
| E            | user_name  | 投票者名稱     |
| F            | created_at | 時間           |

### Sheet: `Logs` (日誌)

| Column Index | Field       | Description            |
| :----------- | :---------- | :--------------------- |
| A            | upload_time | 上傳時間 (Server Time) |
| B            | device_id   | 裝置 ID                |
| C            | device_name | 裝置名稱               |
| D            | timestamp   | 日誌時間 (Client Time) |
| E            | level       | 等級 (Info/Error/Warn) |
| F            | source      | 來源模組               |
| G            | message     | 訊息內容               |
