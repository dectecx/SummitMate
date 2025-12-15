# Google Apps Script 部署指南

## 📋 前置需求

- Google 帳號
- 可以建立 Google Sheets

---

## 🚀 部署步驟

### Step 1: 建立 Google Sheets

1. 前往 [Google Sheets](https://sheets.google.com)
2. 建立新的試算表
3. 命名為 `SummitMate Database`

### Step 2: 建立 Apps Script

1. 在試算表中，點擊 **擴充功能** → **Apps Script**
2. 這會開啟 Apps Script 編輯器
3. 刪除預設的 `myFunction` 程式碼
4. 複製 `Code.gs` 的全部內容貼上

### Step 3: 初始化工作表

1. 在 Apps Script 編輯器中，選擇函式 `setupSheets`
2. 點擊 **執行** ▶️
3. 首次執行會要求授權，點擊 **審查權限** → 選擇你的帳號 → **允許**
4. 執行完成後，回到試算表應該會看到：
   - `Itinerary` 工作表 (含範例行程)
   - `Messages` 工作表 (含歡迎訊息)

### Step 4: 部署為網頁應用程式

1. 點擊右上角 **部署** → **新增部署作業**
2. 點擊齒輪圖示 ⚙️ 選擇 **網頁應用程式**
3. 設定：
   - **描述**: `SummitMate API v1`
   - **執行身分**: `我`
   - **誰可以存取**: `任何人`
4. 點擊 **部署**
5. **複製** 網頁應用程式 URL (類似 `https://script.google.com/macros/s/xxx/exec`)

### Step 5: 更新 Flutter App

1. 開啟 `lib/core/constants.dart`
2. 將 `gasBaseUrl` 更新為您的 URL：

```dart
static const String gasBaseUrl = 'https://script.google.com/macros/s/YOUR_ID/exec';
```

3. 重新執行 App：`flutter run`

---

## 📊 Sheets 結構

### Itinerary (行程)

| Column | Type | 說明 |
|--------|------|------|
| day | String | D0, D1, D2 |
| name | String | 地點名稱 |
| est_time | String | 預計時間 HH:MM |
| altitude | Number | 海拔 (公尺) |
| distance | Number | 累計里程 (公里) |
| note | String | 備註 |
| image_asset | String | 圖片檔名 (optional) |

### Messages (留言)

| Column | Type | 說明 |
|--------|------|------|
| uuid | String | 唯一識別碼 |
| parent_id | String | 父留言 UUID (回覆用) |
| user | String | 發文者暱稱 |
| category | String | Gear / Plan / Misc |
| content | String | 留言內容 |
| timestamp | DateTime | 發文時間 |

---

## 🧪 測試 API

部署完成後，可以在瀏覽器測試：

```
YOUR_URL?action=fetch_all
```

應該會回傳 JSON：
```json
{
  "itinerary": [...],
  "messages": [...]
}
```

---

## ⚠️ 注意事項

1. **每次修改 Code.gs 後**，需要重新部署才會生效
2. 部署時選擇 **新增部署作業**，不要覆蓋舊的，這樣可以保留版本歷史
3. URL 是公開的，任何知道 URL 的人都可以存取
4. 如需更高安全性，可以加入 API Key 驗證 (進階)
