# SummitMate (山友)

## 專案概述 (Project Overview)

SummitMate 是一款針對嘉明湖登山行程設計的跨平台應用程式（iOS/Android）。核心設計原則為 **Offline First（離線優先）**，確保在無網路的高山環境下，仍能執行行程控管、裝備檢核與緊急資訊查詢。行前協作則透過 Google Sheets 作為 CMS，實現輕量化的團隊同步。

## 功能摘要 (Key Features)

### 離線核心 (Offline Core)

* **動態行程表**：支援預計時間與實際時間的比對，允許跳躍式打卡與修正。
* **個人裝備清單**：類似 LighterPack 的裝備重量計算與打包檢核（資料僅存於本地）。
* **靜態圖資**：內建關鍵地標與岔路口照片，不依賴網路加載。
* **緊急資訊**：離線存取的電話與座標資訊。

### 線上協作 (Online Collaboration)

* **團隊留言板**：支援巢狀留言（Threaded Comments）與分類顯示（裝備/行程/其他）。
* **身分識別**：基於本地儲存的暱稱系統。
* **單向/雙向同步**：
  * 行程表：Google Sheets -> App (單向下載)。
  * 留言板：Google Sheets <-> App (雙向同步)。

## 技術堆疊 (Tech Stack)

* **Frontend**: Flutter (Dart)
* **Local Database**: Isar (NoSQL)
* **Cloud Backend**: Google Sheets (Database) + Google Apps Script (API Gateway)
* **External Service**: Open-Meteo / Windy / CWA (via URL Launcher)

## 環境建置 (Setup)

### 1. Flutter 環境

* Flutter SDK: `3.x` (Stable)
* Dart SDK: `3.x`

### 2. 依賴套件 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  isar: ^3.1.0        # 本地資料庫
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.0.0
  http: ^1.1.0        # API 請求
  provider: ^6.0.0    # 狀態管理
  intl: ^0.18.0       # 時間格式化
  uuid: ^4.0.0        # 生成 Message ID
  shared_preferences: ^2.2.0 # 儲存簡單設定 (User Name)
  url_launcher: ^6.1.0 # 開啟外部天氣網頁
  font_awesome_flutter: ^10.6.0 # 圖示庫

dev_dependencies:
  isar_generator: ^3.1.0
  build_runner: ^2.4.0