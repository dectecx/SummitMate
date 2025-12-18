# SummitMate (山友)

## 專案概述 (Project Overview)

SummitMate 是一款針對嘉明湖登山行程設計的跨平台應用程式，支援 **iOS**, **Android** 與 **Web (PWA)**。核心設計原則為 **Offline First（離線優先）**，確保在無網路的高山環境下，仍能執行行程控管、裝備檢核與緊急資訊查詢。行前協作則透過 Google Sheets 作為 CMS，實現輕量化的團隊同步。

## 功能摘要 (Key Features)

### 離線核心 (Offline Core)

* **動態行程表**：支援預計時間與實際時間的比對，允許跳躍式打卡與修正。
* **行程編輯管理**：完整 CRUD 功能，可自訂行程節點與時間，支援雲端備份覆寫。
* **個人裝備清單**：類似 LighterPack 的裝備重量計算與打包檢核。
* **本地日誌系統**：記錄操作日誌，支援查閱與雲端上傳 (Web 相容)。

### 線上協作 (Online Collaboration)

* **團隊留言板**：支援巢狀留言與分類顯示。
* **Google Sheets 同步**：雙向同步留言，單向下載行程，並支援 Web 版跨域上傳。

### 跨平台支援 (Cross-Platform)

* **Mobile (iOS/Android)**：原生體驗，完整硬體支援。
* **Web / PWA**：
  * **PWA 安裝**：支援 iOS (Safari Add to Home Screen) 與 Android 安裝。
  * **響應式設計**：電腦版自動適配寬度 (Max 600px)，保持最佳瀏覽比例。
  * **離線支援**：Hive DB 支援 Web IndexedDB持久化。

## 技術堆疊 (Tech Stack)

* **Framework**: Flutter 3.x (Dart 3.x)
* **Platforms**: iOS, Android, Web (HTML/CanvasKit)
* **Local Database**: Hive (NoSQL, Web-Compatible)
* **State Management**: Provider
* **Backend**: Google Sheets + Google Apps Script (REST API)

## 專案文件 (Documentation)

詳細設計文件請參閱 `docs/` 目錄：

* [⛰️ 產品路線圖 (Roadmap)](docs/ROADMAP.md) - 開發進度與未來規劃
* [📐 架構與資料庫 (Architecture)](docs/ARCHITECTURE_AND_SCHEMA.md) - 系統架構與 Schema 設計
* [🌊 UI/UX 流程 (Flow)](docs/UI_UX_FLOW.md) - 頁面流程圖
* [📱 UI 線框圖 (Wireframes)](docs/UI_WIREFRAMES.md) - 介面設計草圖
* [🚀 部署指南 (Deployment)](docs/google_apps_script/DEPLOYMENT.md) - Google Apps Script 與 Web 部署
* [🔒 隱私權政策 (Privacy)](docs/PRIVACY_POLICY.md)

## 環境建置 (Setup)

### 1. 環境變數
建立 `.env.dev` 檔案：
```properties
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

### 2. 執行應用
```bash
# Mobile (iOS/Android)
flutter run --dart-define-from-file=.env.dev

# Web (Chrome) - 自動選擇 Render (HTML/CanvasKit)
flutter run -d chrome --dart-define-from-file=.env.dev
```

### 3. 建置發布
```bash
# Android APK
flutter build apk --dart-define-from-file=.env.prod

# Web (Static Files to build/web)
flutter build web --release --dart-define-from-file=.env.prod
```
