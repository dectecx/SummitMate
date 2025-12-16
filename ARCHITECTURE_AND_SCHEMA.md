# 系統架構與資料規格 (Architecture & Schema Spec)

## 1. 資料流架構 (Data Flow)

```mermaid
graph TD
    User[使用者] <--> FlutterApp

    subgraph Local [本地端]
        FlutterApp <--> Hive[(Hive Database)]
        FlutterApp <--> SharedPreferences[偏好設定]
    end

    subgraph Cloud [雲端]
        FlutterApp -- HTTP GET/POST --> GAS[Google Apps Script]
        GAS <--> GSheets[Google Sheets]
    end
```

## 2. 專案架構 (Project Structure)

```
lib/
├── core/
│   ├── constants.dart      # 常數定義
│   ├── di.dart             # 依賴注入 (GetIt)
│   ├── env_config.dart     # 環境配置
│   └── theme.dart          # 主題配置
├── data/
│   ├── models/             # 資料模型
│   │   ├── settings.dart
│   │   ├── itinerary_item.dart
│   │   ├── message.dart
│   │   └── gear_item.dart
│   └── repositories/       # 資料存取層
│       ├── settings_repository.dart
│       ├── itinerary_repository.dart
│       ├── message_repository.dart
│       └── gear_repository.dart
├── services/
│   ├── isar_service.dart   # Hive 資料庫服務
│   ├── google_sheets_service.dart
│   ├── sync_service.dart
│   ├── toast_service.dart
│   └── log_service.dart
├── presentation/
│   └── providers/          # 狀態管理
│       ├── settings_provider.dart
│       ├── itinerary_provider.dart
│       ├── message_provider.dart
│       └── gear_provider.dart
└── main.dart
```

## 3. 本地資料庫設計 (Hive Schema)

### Box: `settings`

用於儲存全域設定。

| Field | Type | Description |
| :--- | :--- | :--- |
| `username` | String | 使用者暱稱 (用於留言識別) |
| `lastSyncTime` | DateTime? | 上次同步時間 |

### Box: `itinerary`

行程節點，來源：由 Google Sheets 下載覆寫，但 `actualTime` 保留本地紀錄。

| Field | Type | Description |
| :--- | :--- | :--- |
| `day` | String | e.g., "D0", "D1", "D2" |
| `name` | String | 地標名稱 (e.g., "向陽山屋") |
| `estTime` | String | 預計時間 (HH:mm) |
| `actualTime`| DateTime? | **本地欄位**，實際打卡時間 |
| `altitude` | int | 海拔 (m) |
| `distance` | double | 里程 (K) |
| `note` | String | 備註 |
| `imageAsset`| String? | 對應 assets 圖片檔名 |

### Box: `messages`

留言，來源：與 Google Sheets 雙向同步。

| Field | Type | Description |
| :--- | :--- | :--- |
| `uuid` | String | **Unique ID** (後端識別用) |
| `parentId` | String? | 若為 null 則為主留言，否則為子留言 |
| `user` | String | 發文者暱稱 |
| `category` | String | "Gear", "Plan", "Misc" |
| `content` | String | 留言內容 |
| `timestamp` | DateTime | 發文時間 |

### Box: `gear`

個人裝備，來源：僅存於本地，不與雲端同步。

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | String | 裝備名稱 |
| `weight` | double | 重量 (g) |
| `category` | String | "Sleep", "Cook", "Wear", "Other" |
| `isChecked` | bool | 打包狀態 |

### Box: `app_logs`

應用日誌，用於除錯與問題追蹤。

| Field | Type | Description |
| :--- | :--- | :--- |
| `timestamp` | DateTime | 日誌時間 |
| `level` | String | "debug", "info", "warning", "error" |
| `message` | String | 日誌訊息 |
| `source` | String? | 來源模組 |

---

## 4. Google Sheets 資料結構 (Cloud Schema)

### Sheet 1: `Itinerary`

| day (A) | name (B) | est_time (C) | altitude (D) | distance (E) | note (F) | image_asset (G) |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | 向陽山屋 | 11:30 | 2850 | 4.3 | 午餐點 | cabin.jpg |

### Sheet 2: `Messages`

| uuid (A) | parent_id (B) | user (C) | category (D) | content (E) | timestamp (F) |
| --- | --- | --- | --- | --- | --- |
| (UUID) | (UUID or Empty) | String | String | String | DateTime |

### Sheet 3: `Logs` (新增)

用於接收 App 上傳的日誌。

| upload_time (A) | device_id (B) | device_name (C) | timestamp (D) | level (E) | source (F) | message (G) |
| --- | --- | --- | --- | --- | --- | --- |
| ISO8601 | String | String | ISO8601 | String | String | String |

---

## 5. API 介面 (Google Apps Script)

### Endpoint: `doGet(e)`

**Action**: `fetch_all`

**Response (JSON)**:

```json
{
  "itinerary": [
    { "day": "D1", "name": "...", "est_time": "...", ... }
  ],
  "messages": [
    { "uuid": "...", "parent_id": null, "content": "...", ... }
  ]
}
```

**Action**: `health`

```json
{ "status": "ok", "timestamp": "2024-12-16T10:00:00Z" }
```

### Endpoint: `doPost(e)`

**Action**: `add_message`

```json
{
  "action": "add_message",
  "data": {
    "uuid": "generated-uuid-v4",
    "parent_id": null,
    "user": "Alex",
    "category": "Gear",
    "content": "我帶爐頭",
    "timestamp": "2023-10-12T09:00:00Z"
  }
}
```

**Action**: `delete_message`

```json
{
  "action": "delete_message",
  "uuid": "target-uuid"
}
```

**Action**: `upload_logs` (新增)

```json
{
  "action": "upload_logs",
  "logs": [
    { "timestamp": "...", "level": "info", "message": "...", "source": "..." }
  ],
  "device_info": {
    "device_id": "...",
    "device_name": "SummitMate App"
  }
}
```

---

## 6. 依賴注入 (Dependency Injection)

使用 `GetIt` 進行服務註冊：

```dart
// 初始化順序
1. SharedPreferences
2. HiveService
3. LogService
4. Repositories (Settings, Itinerary, Message, Gear)
5. Services (GoogleSheetsService, SyncService)
```

---

## 7. 環境配置 (Environment Configuration)

使用 `--dart-define-from-file` 注入環境變數：

```
# .env.dev
GAS_BASE_URL=https://script.google.com/macros/s/DEV_ID/exec

# .env.prod
GAS_BASE_URL=https://script.google.com/macros/s/PROD_ID/exec
```

執行：
```bash
flutter run --dart-define-from-file=.env.dev
```
