# Google Apps Script 部署與 Web 發布指南

## 📋 前置需求

- Google 帳號
- 可以建立 Google Sheets
- Flutter SDK (Web 支援)

---

## 🚀 此專案部署流程 (Backend)

### Step 1: 建立 Google Sheets 與 Apps Script

1. 前往 [Google Sheets](https://sheets.google.com) 建立新試算表 `SummitMate Database`。
2. 點擊 **擴充功能** → **Apps Script**。
3. 刪除預設代碼，將 `docs/google_apps_script/Code.gs` 內容完整複製貼上。
4. 點擊 💾 **儲存**。

### Step 2: 初始化資料庫

1. 在 Apps Script 編輯器中選擇函式 `setupSheets`。
2. 點擊 **執行** ▶️ (首次需授權)。
3. 確認試算表已建立 `Itinerary`, `Messages`, `Logs` 三個工作表。

### Step 3: 部署 API

1. 右上角 **部署** → **新增部署作業**。
2. 類型：**網頁應用程式**。
3. 設定：
   - 描述: `SummitMate API v1`
   - 執行身分: `我`
   - 誰可以存取: `任何人` (關鍵！否則 App 無法存取)
4. **部署** 並複製 URL。

### Step 4: 配置 Flutter 環境

建立 `.env.dev` (開發) 與 `.env.prod` (生產):
```properties
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

---

## 🌐 Web 版部署流程 (Frontend)

SummitMate 支援 PWA (Progressive Web App)，可部署至 GitHub Pages 或 Firebase Hosting。

### Step 1: 建置 Web 版

```bash
# 生產環境建置 (Minified)
flutter build web --release --dart-define-from-file=.env.prod
```

### Step 2: 部署 (以 Firebase Hosting 為例)

1. 安裝 Firebase CLI: `npm install -g firebase-tools`
2. 初始化: `firebase init hosting` (選擇 `build/web` 作為 public 目錄)
3. 部署: `firebase deploy`

---

## � API 端點參考

Base URL: `macros/s/{DEPLOYMENT_ID}/exec`

### GET 請求
| Action | 說明 | 回傳範例 |
|--------|------|----------|
| `fetch_all` | 取得全部資料 | `{ "itinerary": [...], "messages": [...] }` |
| `health` | 健康檢查 | `{ "status": "ok" }` |

### POST 請求
*(注意: Web 版需使用 `Content-Type: text/plain` 以避開 CORS Preflight)*

| Action | Payload Data | 說明 |
|--------|--------------|------|
| `add_message` | Mesage JSON | 新增單筆留言 |
| `batch_add_messages` | List\<Message\> | 批次新增留言 |
| `delete_message` | `{ uuid: "..." }` | 刪除留言 |
| `update_itinerary` | List\<ItineraryItem\> | 覆寫整個行程表 |
| `upload_logs` | List\<LogEntry\> | 上傳除錯日誌 |

---

## 🔧 疑難排解 (Troubleshooting)

### Q1: Web 版出現 `Failed to fetch` 或 CORS 錯誤？
**原因**:瀏覽器發送了 OPTIONS 預檢請求，但 GAS 不支援。
**解法**: 確保前端送出的 POST 請求 `Content-Type` 為 `text/plain`。這會觸發 Simple Request 機制，直接 POST 而不預檢。GAS 會解析 Body 內容為 JSON。

### Q2: App 收到 302 Redirect？
**正常現象**。GAS 的 `doPost` 回傳機制是透過 Redirect 轉導到回應頁面。
- **Mobile**: `http` 套件需手動處理 302 跟隨。
- **Web**: 瀏覽器會自動跟隨，前端直接接收 200 回應。

### Q3: 部署後修改 Code.gs 沒生效？
**必要步驟**：每次修改後，必須建立 **新版本 (New Version)** 的部署。
1. **管理部署作業** → 編輯 icon ✏️
2. 版本：選擇「新版本」
3. 部署 (URL 不變)
