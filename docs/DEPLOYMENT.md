# 部署指南 (Deployment Guide)

本文件涵蓋 **Backend (Google Apps Script)** 與 **Frontend (Flutter Web / GitHub Pages)** 的完整部署流程。

---

## ☁️ Backend: Google Apps Script

### 1. 建立服務
1. 建立新的 Google Sheet，命名為 `SummitMate Database`。
2. 擴充功能 > Apps Script，貼上 `docs/google_apps_script/Code.gs` 內容。
3. 執行 `setupSheets` 初始化資料表。

### 2. 部署 API
1. 部署 > 新增部署作業 > **網頁應用程式**。
2. 誰可以存取: **任何人** (關鍵)。
3. 複製 Deployment URL。

### 3. 環境變數配置
建立 `.env.prod` 檔案：
```properties
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

---

## 🌐 Frontend: GitHub Pages 部署

SummitMate 支援部署為 PWA (Progressive Web App) 並託管於 GitHub Pages。由於 GitHub Pages 的 URL 結構為 `username.github.io/repo_name/`，建置時必須指定 `base-href`。

### 方法一：使用 peanut 工具 (推薦) 🥜

`peanut` 是一個專門將 Flutter Web 建置並推送到 `gh-pages` 分支的工具，無需手動切換分支。

#### 1. 前置準備
確保 `docs/google_apps_script/Code.gs` 中的 Web POST 處理已更新 Code.gs 的 `doPost` 函式 (支援 text/plain)。

#### 2. 安裝與執行
```bash
# 1. 啟用 peanut
dart pub global activate peanut

# 2. 建置並推送到 gh-pages 分支
# --base-href: 必須設定為 /你的Repo名稱/
# --web-renderer: 建議使用 auto 或 html (為了相容性)
# 改用 dart pub global run 以避免 PATH 設定問題
dart pub global run peanut --extra-args "--base-href=/SummitMate/ --dart-define-from-file=.env.prod"

# 3. 推送到遠端
git push origin --set-upstream gh-pages
```

#### 3. 設定 GitHub Pages
1. 前往 GitHub Repo > **Settings** > **Pages**。
2. Source: **Deploy from a branch**。
3. Branch: 選擇 `gh-pages` / `/ (root)`。
4. Save。
5. 等待數分鐘後，您的 App 將在 `https://dectecx.github.io/SummitMate/` 上線。

---

### 方法二：手動建置 (Manual)

如果您不想安裝額外工具，可手動建置並將 `build/web` 內容推送到分支。

#### 1. 建置 Web 版
使用 `--release` 與 `--base-href` 建置。

```bash
flutter build web --release --base-href /SummitMate/ --dart-define-from-file=.env.prod
```

生成的檔案位於 `build/web/`。

#### 2. 部署
將 `build/web/` 的內容複製並 commit 到名為 `gh-pages` 的分支，然後推送。

---

## 🔧 常見問題排除 (Troubleshooting)

### Q1: 打開網頁一片空白？
*   **檢查 Base HREF**: 打開瀏覽器 Console (F12)。如果看到 js/css 404 錯誤，表示 `--base-href` 設定錯誤。確保它前後都有 `/` (例如 `/SummitMate/`)。
*   **檢查 Renderer**: 某些舊裝置不支援 CanvasKit。可嘗試改用 HTML renderer 重建：
    ```bash
    flutter build web --web-renderer html --base-href ...
    ```

### Q2: 無法登入/上傳資料 (CORS Error)？
*   **Google Apps Script**: 確保 `doPost` 支援 `text/plain` 並正確解析。
*   **Content-Type**: Flutter Web 版需確保發送 `Content-Type: text/plain`。
*   **部署權限**: 確認 GAS 部署設定為「任何人」可存取。

### Q3: 圖片無法顯示？
*   確認 `assets` 是否有在 `pubspec.yaml` 中正確宣告。
*   Web 版圖片路徑有時對大小寫敏感。

---

## 📱 Mobile (Android APK)

```bash
flutter build apk --dart-define-from-file=.env.prod
```
檔案位於 `build/app/outputs/flutter-apk/app-release.apk`。
