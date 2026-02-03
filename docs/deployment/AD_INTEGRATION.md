# AdMob 整合指南 (AD_INTEGRATION.md)

## 1. 概述 (Overview)

本文件說明 SummitMate 應用程式的 AdMob 整合策略，涵蓋用戶體驗、架構設計與安全規範。

### 核心策略

- **橫幅廣告 (Banner Ads)**: 常駐顯示於主要導航分頁 (Trips, Gear, Info, Interaction) 的底部。
- **插頁式廣告 (Interstitial Ads)**: 在關鍵用戶操作後顯示 (例如：建立行程)，目前 **暫時停用**。
- **獎勵廣告 (Rewarded Ads)**: 已預先實作底層邏輯，以支援未來功能 (例如：「觀看廣告解鎖裝備」)。

---

## 2. 架構設計 (Architecture)

### 2.1 UI 元件層

- **`BannerAdWidget`**: 負責處理廣告載入與生命週期的可重用元件。位於 `lib/presentation/widgets/ads/`。
- **整合方式**: 嵌入於 `MainNavigationScreen` 中，確保在切換分頁時廣告能保持常駐不中斷。

### 2.2 服務層

- **`IAdService` / `AdService`**: 管理 Google Mobile Ads SDK 的初始化，並處理插頁式與獎勵廣告的邏輯。
- **`AdHelper`**: 靜態輔助類別，負責管理廣告單元 ID (Ad Unit IDs) 與環境檢查。

---

## 3. 設定與安全 (Configuration & Security)

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

- **機制**: `Info.plist` 使用變數替換功能 `$(ADMOB_APP_ID)`。
- **實作**: 需在 `Podfile` 中加入 `post_install` 腳本，從 `local.properties` 讀取 ID 並注入至 Xcode Build Settings。

### 3.2 廣告單元 ID (Unit IDs)

Banner 與 Interstitial 的 Unit IDs 設定於 `.env` 檔案 (`.env.dev`, `.env.prod`)，並透過 `EnvConfig` 載入。

- **防呆機制**: 若處於 Debug 模式或環境變數缺失，`AdHelper` 會強制使用 Test IDs 以確保安全。

---

## 4. 實作指南 (Implementation Guide)

### 4.1 本地開發 (Local Development)

- **預設情況**: 無需任何設定，系統將自动使用 Google Test IDs。
- **測試真實廣告**: 請在 `android/local.properties` 中加入一行 `ADMOB_APP_ID=您的真實ID`。

### 4.2 iOS 設定指南 (Mac 環境)

請將以下腳本加入 `ios/Podfile`，以實現從 `local.properties` 統一管理雙平台 ID：

```ruby
post_install do |installer|
  # 1. 讀取 ../android/local.properties 中的 ADMOB_APP_ID
  admob_app_id = 'ca-app-pub-3940256099942544~1458002511' # 預設 fallback 使用 Test ID

  local_props_path = File.join(Dir.pwd, '..', 'android', 'local.properties')
  if File.exist?(local_props_path)
    File.readlines(local_props_path).each do |line|
      if line.strip.start_with?('ADMOB_APP_ID=')
        admob_app_id = line.strip.split('=').last
      end
    end
  end

  # 2. 將 ID 注入至所有 Target 的 Build Settings
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ADMOB_APP_ID'] = admob_app_id
    end
  end
end
```
