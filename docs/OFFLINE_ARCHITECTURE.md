# 離線優先架構 (Offline-First Architecture)

本文件說明 SummitMate 的離線優先架構設計與實作細節。

---

## 架構概覽

```mermaid
flowchart TB
    subgraph Presentation["Presentation Layer"]
        P1["Providers"]
        UI["Screens/Widgets"]
    end

    subgraph Services["Services Layer"]
        CS["ConnectivityService"]
        AS["GasAuthService"]
        SS["SyncService"]
    end

    subgraph Data["Data Layer"]
        REPO["Repositories"]
        HIVE["Hive (Local)"]
        API["GAS API (Remote)"]
    end

    UI --> P1
    P1 --> CS
    P1 --> SS
    AS --> CS
    SS --> CS
    SS --> REPO
    REPO --> HIVE
    SS --> API
```

---

## 離線模式判斷

### ConnectivityService

統一的離線判斷服務，整合：

- **網路狀態**: `InternetConnectionChecker`
- **App 離線設定**: `settings.isOfflineMode`

```dart
// lib/services/connectivity_service.dart
bool get isOffline => !_hasConnection || isOfflineModeEnabled;
```

使用方式：

```dart
if (getIt<ConnectivityService>().isOffline) {
  // 執行離線邏輯
}
```

---

## 登出資料策略

### 登出時

| 資料類型            | 行為                      |
| ------------------- | ------------------------- |
| Provider 記憶體狀態 | **清除** (呼叫 `reset()`) |
| Session Token       | **清除**                  |
| Hive 本地資料       | **保留** (供離線登入使用) |

### 手動清除

透過開發選項的「清除本地資料」功能，完整清除所有 Hive 資料。

---

## 離線登入

### 流程

```mermaid
flowchart LR
    A["用戶輸入帳密"] --> B{"網路可用?"}
    B -->|是| C["API 登入"]
    B -->|否| D["檢查快取 Session"]
    D --> E{"Email 匹配<br>且 Token < 7天?"}
    E -->|是| F["離線登入成功"]
    E -->|否| G["登入失敗"]
    C --> F
```

### 7 天寬限期

離線登入時，Token 必須在發行後 7 天內才有效：

```dart
final tokenAge = DateTime.now().difference(validationResult.payload!.issuedAt);
if (tokenAge < const Duration(days: 7)) {
  // 離線登入成功
}
```

---

## 資料同步策略

| 情境     | 策略                         |
| -------- | ---------------------------- |
| 線上模式 | 先讀本地快取，背景同步遠端   |
| 離線模式 | 只讀本地 Hive，禁用寫入操作  |
| 恢復連線 | 自動觸發同步 (有 5 分鐘節流) |

---

## 相關檔案

| 功能           | 檔案                                     |
| -------------- | ---------------------------------------- |
| 離線判斷       | `lib/services/connectivity_service.dart` |
| 離線登入       | `lib/services/gas_auth_service.dart`     |
| 同步服務       | `lib/services/sync_service.dart`         |
| Provider Reset | `lib/presentation/providers/*.dart`      |
| DI 註冊        | `lib/core/di.dart`                       |
