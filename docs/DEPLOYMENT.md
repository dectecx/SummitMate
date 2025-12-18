# 部署指南 (Deployment Guide)

本文件說明 SummitMate 後端 (Google Apps Script) 與前端 (Flutter Web) 的部署流程。

---

## 1. Google Apps Script (Backend)

### 部署步驟

1.  **建立專案**
    *   建立 Google Sheet，命名為 `SummitMate Database`。
    *   開啟 **擴充功能** > **Apps Script**。
    *   複製 `docs/google_apps_script/Code.gs` 內容至編輯器。

2.  **初始化資料**
    *   執行 `setupSheets` 函式以建立 `Itinerary`, `Messages`, `Logs` 工作表。

3.  **發布 API**
    *   點擊 **部署** > **新增部署作業**。
    *   類型選擇 **網頁應用程式**。
    *   存取權限設定為 **任何人**。
    *   部署並取得 URL。

4.  **環境設定**
    *   將 URL 填入 `.env.prod` (本地開發用) 或 GitHub Secrets (CI/CD 用)。
    *   Key: `GAS_BASE_URL`

---

## 2. Flutter Web Deployment

本專案支援多種 Web 部署方式，以下列出 Netlify 與 GitHub Pages 的配置流程。

### 方式 A: Netlify (Via GitHub Actions)

此方式透過 CI/CD 自動建置並部署至 Netlify。

#### 1. Netlify 設定
1.  新增網站 (Import from Git 或 Deploy manually)。
2.  取得 **Site ID** (`Site settings` > `Site details` > `API ID`)。
3.  取得 **Access Token** (`User settings` > `OAuth` > `New access token`)。

#### 2. GitHub Secrets 設定
於 GitHub Repository 的 `Settings` > `Secrets and variables` > `Actions` 新增以下變數：

| Name | Description |
|------|-------------|
| `NETLIFY_SITE_ID` | Netlify Site API ID |
| `NETLIFY_AUTH_TOKEN` | Netlify Personal Access Token |
| `GAS_BASE_URL` | Google Apps Script Web App URL |

#### 3. 觸發部署
推送程式碼至 `main` 分支即自動觸發 `.github/workflows/deploy_to_netlify.yml` 流程。

---

### 方式 B: GitHub Pages

此方式透過 `peanut` 工具建置並推送到 `gh-pages` 分支。

#### 1. 前置需求
*   Flutter SDK
*   Dart SDK

#### 2. 建置與推送
執行以下指令將 Web 版建置至 `gh-pages` 分支：

```bash
# 啟用 peanut
dart pub global activate peanut

# 建置 (需指定 repository 名稱作為 base-href)
dart pub global run peanut --extra-args "--base-href=/SummitMate/ --dart-define-from-file=.env.prod"

# 推送
git push origin --set-upstream gh-pages
```

#### 3. 啟用 Pages
於 GitHub Repository 的 `Settings` > `Pages` 設定：
*   **Source**: Deploy from a branch
*   **Branch**: `gh-pages` / `/ (root)`

---

## 3. Android Deployment

建置 Release APK：

```bash
flutter build apk --dart-define-from-file=.env.prod
```

輸出路徑：`build/app/outputs/flutter-apk/app-release.apk`
