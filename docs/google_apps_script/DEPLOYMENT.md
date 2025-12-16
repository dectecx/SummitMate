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
5. 點擊 💾 **儲存**

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

### Step 5: 建立環境設定檔

在專案根目錄建立 `.env.dev` 檔案：

```
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

### Step 6: 執行 Flutter App

```bash
flutter run --dart-define-from-file=.env.dev
```

---

## 🔄 更新部署

當修改 `Code.gs` 後，需要重新部署才會生效：

### 方法一：更新現有部署 (推薦)

1. 點擊 **部署** → **管理部署作業**
2. 點擊現有部署的 ✏️ **編輯** 圖示
3. 在 **版本** 下拉選單中選擇 **新版本**
4. 點擊 **部署**
5. **URL 不會改變**，App 不需要更新

### 方法二：建立新部署

1. 點擊 **部署** → **新增部署作業**
2. 設定同 Step 4
3. **會產生新 URL**，需要更新 `.env.dev`

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

### Logs (日誌) - 自動建立

| Column | Type | 說明 |
|--------|------|------|
| upload_time | DateTime | 上傳時間 |
| device_id | String | 設備 ID |
| device_name | String | 設備名稱 |
| timestamp | DateTime | 日誌時間 |
| level | String | debug/info/warning/error |
| source | String | 來源模組 |
| message | String | 日誌訊息 |

---

## 🧪 測試 API

部署完成後，可以在瀏覽器測試：

### 健康檢查
```
YOUR_URL?action=health
```

回傳：
```json
{ "status": "ok", "timestamp": "2024-12-16T10:00:00Z" }
```

### 取得所有資料
```
YOUR_URL?action=fetch_all
```

回傳：
```json
{
  "itinerary": [...],
  "messages": [...]
}
```

---

## 📱 API 端點

### GET 請求

| Action | 說明 |
|--------|------|
| `fetch_all` | 取得行程和留言 |
| `health` | 健康檢查 |

### POST 請求

| Action | 說明 |
|--------|------|
| `add_message` | 新增留言 |
| `delete_message` | 刪除留言 |
| `upload_logs` | 上傳日誌 |

---

## ⚠️ 注意事項

1. **每次修改 Code.gs 後**，需要建立新版本才會生效
2. 使用「管理部署作業」更新版本，URL 不會改變
3. URL 是公開的，任何知道 URL 的人都可以存取
4. 如需更高安全性，可以加入 API Key 驗證 (進階)

---

## 🔧 疑難排解

### App 收到 302 錯誤但資料寫入成功

這是正常行為。GAS 的 POST 請求會返回 302 重定向，App 已處理此情況。

### 找不到工作表

執行 `setupSheets` 函式來初始化工作表。

### 授權錯誤

重新執行任一函式，系統會要求重新授權。
