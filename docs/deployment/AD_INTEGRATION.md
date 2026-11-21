# AdMob 整合指南

## 1. 概述

本文件說明 SummitMate 應用程式的 AdMob 整合策略，涵蓋用戶體驗、架構設計與安全規範。

### 核心策略

- **橫幅廣告 (Banner Ads)**: 常駐顯示於主要導航分頁 (Trips, Gear, Info, Interaction) 的底部。
- **插頁式廣告 (Interstitial Ads)**: 在關鍵用戶操作後顯示 (例如：建立行程)，目前 **暫時停用**。
- **獎勵廣告 (Rewarded Ads)**: 已預先實作底層邏輯，以支援未來功能 (例如：「觀看廣告解鎖裝備」)。

---

## 2. 架構設計

### 2.1 UI 元件層

- **`BannerAdWidget`**: 負責處理廣告載入與生命週期的可重用元件。位於 `lib/presentation/widgets/ads/`。
- **整合方式**: 嵌入於 `MainNavigationScreen` 中，確保在切換分頁時廣告能保持常駐不中斷。

### 2.2 服務層

- **`IAdService` / `AdService`**: 管理 Google Mobile Ads SDK 的初始化，並處理插頁式與獎勵廣告的邏輯。
- **`AdHelper`**: 靜態輔助類別，負責管理廣告單元 ID (Ad Unit IDs) 與環境檢查。

---

## 3. 設定與安全

### 3.1 App ID 管理策略

為了平衡開發便利性與安全性 (避免將真實 ID 上傳至 Git)，本專案採用 **動態注入策略 (Dynamic Injection Strategy)**。

#### Android

- **機制**: 透過 `build.gradle.kts` 動態讀取 App ID。
- **讀取順序 (優先權)**:
  1.  `local.properties` (`ADMOB_APP_ID=...`) - 用於本地測試真實廣告。
  2.  環境變數 (`ADMOB_APP_ID`) - 用於 CI/CD 自動化部署。
  3.  **預設值**: Google Test ID (安全備援)。
- **實作**: `AndroidManifest.xml` 使用 `${admobAppId}` 佔位符。

#### iOS

- **機制**: `Info.plist` 使用變數替換功能 `$(ADMOB_APP_ID)`，值由 xcconfig 提供。
- **讀取順序 (優先權)**:
  1.  `ios/Flutter/AdMobLocal.xcconfig` (已被 Git 忽略) - 本地或 CI 放入真實 App ID。
  2.  **預設值**: `ios/Flutter/AdMob.xcconfig` 內的 Google iOS Test ID (安全備援)。
- **注意**: 若 `ADMOB_APP_ID` 沒有定義，Google Mobile Ads SDK 會在啟動時直接中止 App (閃退)，因此預設值不可移除。

### 3.2 廣告單元 ID (Unit IDs)

Banner 與 Interstitial 的 Unit IDs 設定於 `.env` 檔案 (`.env.dev`, `.env.prod`)，並透過 `EnvConfig` 載入。

- **防呆機制**: 若處於 Debug 模式或環境變數缺失，`AdHelper` 會強制使用 Test IDs 以確保安全。

---

## 4. 實作指南

### 4.1 本地開發

- **預設情況**: 無需任何設定，系統將自动使用 Google Test IDs。
- **測試真實廣告**: 請在 `android/local.properties` 中加入一行 `ADMOB_APP_ID=您的真實ID`。

### 4.2 iOS 設定指南 (Mac 環境)

- **預設情況**: 無需設定，`ios/Flutter/AdMob.xcconfig` 已提供 Test ID。
- **測試或發佈真實廣告**: 新增 `ios/Flutter/AdMobLocal.xcconfig` (已被 Git 忽略)，內容只需一行：

```text
ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

- **CI/CD**: 在建置前以 Secret 產生同一個檔案即可。
