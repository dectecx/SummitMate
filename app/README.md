# SummitMate (山友)

## 專案概述 (Project Overview)

SummitMate 是一款針對嘉明湖登山行程設計的跨平台應用程式，支援 **iOS**, **Android** 與 **Web (PWA)**。核心設計原則為 **Offline First（離線優先）**，確保在無網路的高山環境下，仍能執行行程控管、裝備檢核與緊急資訊查詢。行前協作則透過 Google Sheets 作為 CMS，實現輕量化的團隊同步。

## 功能摘要 (Key Features)

### 離線核心 (Offline Core)

- **動態行程表**：支援預計時間與實際時間的比對，允許跳躍式打卡與修正。
- **行程編輯管理**：完整 CRUD 功能，可自訂行程節點與時間，支援雲端備份覆寫。
- **個人裝備清單**：類似 LighterPack 的裝備重量計算與打包檢核。
- **本地日誌系統**：記錄操作日誌，支援查閱與雲端上傳 (Web 相容)。

### 線上協作 (Online Collaboration)

- **團隊留言板**：支援巢狀留言與分類顯示，可刪除自己的留言。
- **Google Sheets 同步**：雙向同步留言，單向下載行程，並支援 Web 版跨域上傳。
- **投票功能**：建立團隊投票，支援單選/多選、截止時間與開放新增選項。

### 雲端裝備庫 (Cloud Gear Library)

- **上傳分享**：將個人裝備組合上傳至雲端，供其他山友參考。
- **三層可見性**：
  - 🌐 **Public** - 任何人可查看和下載
  - 🔒 **Protected** - 可見標題，需輸入 Key 下載內容
  - 🔐 **Private** - 不可見，需 Key 才能查看
- **預覽後下載**：下載前可預覽完整裝備清單，按類別縮合顯示。
- **本地 Key 管理**：記住已輸入的 Key，方便日後編輯/刪除。

### 登山氣象 (Hiking Weather)

- **GAS ETL 架構**：Serverless 氣象資料處理，自動從 CWA 擷取並快取。
- **7日預報**：針對高山 (如向陽山) 提供精準 7 日天氣預報。
- **離線快取**：支援離線查看最後更新的氣象資訊。

### 跨平台支援 (Cross-Platform)

- **Mobile (iOS/Android)**：原生體驗，完整硬體支援。
- **Web / PWA**：
  - **PWA 安裝**：支援 iOS (Safari Add to Home Screen) 與 Android 安裝。
  - **響應式設計**：電腦版自動適配寬度 (Max 600px)，保持最佳瀏覽比例。
  - **離線支援**：Hive DB 支援 Web IndexedDB 持久化。

### 教學導覽 (Tutorial)

- **首次使用引導**：9 步驟互動式教學，引導新用戶熟悉各項功能。
- **高亮聚焦**：以 Spotlight 方式高亮目前教學的功能區塊。

## 技術堆疊 (Tech Stack)

- **Framework**: Flutter 3.x (Dart 3.x)
- **Platforms**: iOS, Android, Web (HTML/CanvasKit)
- **Local Database**: Hive (NoSQL, Web-Compatible)
- **State Management**: flutter_bloc (Cubit) + Provider
- **Backend**: Google Sheets + Google Apps Script (REST API)
- **Architecture**: Clean Architecture (Domain, Data, Infrastructure, Presentation)

## 專案文件 (Documentation)

詳細設計文件請參閱根目錄 [`docs/`](../docs/README.md)：

| 分類                                      | 說明               |
| :---------------------------------------- | :----------------- |
| [architecture/](../docs/architecture/)    | 系統架構、模組圖   |
| [database/](../docs/database/)            | Schema、同步機制   |
| [api/](../docs/api/)                      | API 合約           |
| [security/](../docs/security/)            | 權限、隱私政策     |
| [ui/](../docs/ui/)                        | 導航流程、設計準則 |
| [deployment/](../docs/deployment/)        | 部署指南           |
| [project/](../docs/project/)              | 開發路線圖         |

## 環境建置 (Setup)

### 1. 環境變數

在 `app/` 目錄下建立 `.env.dev` 檔案：

```properties
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
# 若需測試氣象功能，請確保 CWA_API_KEY 已配置於 GAS Script Properties
```

### 2. 執行應用

```bash
cd app

# Mobile (iOS/Android)
flutter run --dart-define-from-file=.env.dev

# Web (Chrome) - 自動選擇 Render (HTML/CanvasKit)
flutter run -d chrome --dart-define-from-file=.env.dev
```

### 3. 建置發布

```bash
cd app

# Android APK
flutter build apk --dart-define-from-file=.env.prod

# Web (Static Files to build/web)
flutter build web --release --dart-define-from-file=.env.prod
```
