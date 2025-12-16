# SummitMate (山友)

## 專案概述 (Project Overview)

SummitMate 是一款針對嘉明湖登山行程設計的跨平台應用程式（iOS/Android）。核心設計原則為 **Offline First（離線優先）**，確保在無網路的高山環境下，仍能執行行程控管、裝備檢核與緊急資訊查詢。行前協作則透過 Google Sheets 作為 CMS，實現輕量化的團隊同步。

## 功能摘要 (Key Features)

### 離線核心 (Offline Core)

* **動態行程表**：支援預計時間與實際時間的比對，允許跳躍式打卡與修正。
* **個人裝備清單**：類似 LighterPack 的裝備重量計算與打包檢核（資料僅存於本地）。
* **電話訊號資訊**：內建各地點的通訊覆蓋資訊。
* **本地日誌系統**：記錄操作日誌，支援查閱與雲端上傳。

### 線上協作 (Online Collaboration)

* **團隊留言板**：支援巢狀留言（Threaded Comments）與分類顯示（裝備/行程/其他）。
* **身分識別**：基於本地儲存的暱稱系統。
* **單向/雙向同步**：
  * 行程表：Google Sheets -> App (單向下載)。
  * 留言板：Google Sheets <-> App (雙向同步)。

### UI/UX 特色

* **大自然主題配色**：森林綠主色調，適合戶外使用。
* **四頁籤導航**：行程 / 協作 / 裝備 / 資訊。
* **Toast 通知**：操作反饋清晰。
* **頁面切換動畫**：流暢的淡入過渡效果。

## 技術堆疊 (Tech Stack)

* **Frontend**: Flutter 3.x (Dart 3.x)
* **Local Database**: Hive (NoSQL, 輕量化)
* **State Management**: Provider
* **Dependency Injection**: GetIt
* **Cloud Backend**: Google Sheets + Google Apps Script
* **External Service**: Windy / CWA (via URL Launcher)

## 專案結構 (Project Structure)

```
lib/
├── core/           # 共用工具、常數、主題、DI
├── data/           # 資料層 (Models, Repositories)
├── services/       # 服務層 (API, Sync, Log, Toast)
├── presentation/   # UI 層 (Providers)
└── main.dart
```

## 環境建置 (Setup)

### 1. Flutter 環境

* Flutter SDK: `3.x` (Stable)
* Dart SDK: `3.x`

### 2. 環境設定

建立 `.env.dev` 檔案：

```
GAS_BASE_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

### 3. 執行

```bash
# 開發模式
flutter run --dart-define-from-file=.env.dev

# 執行測試
flutter test

# 打包 APK
flutter build apk --dart-define-from-file=.env.prod
```

### 4. 主要依賴套件

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3          # 本地資料庫
  hive_flutter: ^1.1.0
  path_provider: ^2.0.0
  http: ^1.1.0          # API 請求
  provider: ^6.0.0      # 狀態管理
  get_it: ^7.6.4        # 依賴注入
  intl: ^0.18.0         # 時間格式化
  uuid: ^4.0.0          # 生成 Message ID
  shared_preferences: ^2.2.0
  url_launcher: ^6.1.0
  fluttertoast: ^8.2.4  # Toast 通知

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mocktail: ^1.0.1
```

## 測試覆蓋

* **單元測試**: 36 個 (Models, Services, Providers)
* **執行測試**: `flutter test test/unit`

## 部署

詳見 [Google Apps Script 部署指南](docs/google_apps_script/DEPLOYMENT.md)
