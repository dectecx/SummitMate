# 認證架構 (Authentication Architecture)

SummitMate 採用可抽換的身份驗證架構，支援未來遷移至不同認證後端。

---

## 技術限制

> [!IMPORTANT]
> **限制**：Auth Token 必須注入到 **Request Body** 中，而非 Header。

**原因**：GAS 會剝離自定義 Header，且無法正確處理 CORS 預檢請求。

**解決方案 (`AuthInterceptor`)**：

```dart
if (options.method == 'POST' && options.data is Map<String, dynamic>) {
  (options.data as Map<String, dynamic>)['accessToken'] = token;
}
```

---

## 角色權限系統 (RBAC)

### `roleId` vs `roleCode`

| 欄位                  | 用途      | 範例                       |
| :-------------------- | :-------- | :------------------------- |
| `roleId` (UUID)       | 資料庫 FK | `d290f1ee-6c54-...`        |
| `roleCode` (Constant) | 程式判斷  | `ADMIN`, `LEADER`, `GUIDE` |

### ERD

```mermaid
erDiagram
    Users }|--|| Roles : "assigned"
    Roles ||--|{ RolePermissions : "has"
    Permissions ||--|{ RolePermissions : "belongs"

    Users {
        string id PK
        string role_id FK
        string email
    }
    Roles {
        string id PK
        string code UK
    }
    Permissions {
        string id PK
        string code UK
    }
```

### 扁平化策略

GAS 端 Join 查詢後，回傳 `permissions` 陣列給 App 快取，支援離線權限檢查。

---

## 架構圖

```mermaid
graph TD
    subgraph UI
        AuthCubit
    end
    subgraph Service
        IAuthService --> GasAuthService
        IAuthService -.-> FirebaseAuth[Future]
    end
    subgraph Data
        AuthSessionRepo --> SecureStorage
        AuthInterceptor --> AuthSessionRepo
    end
    subgraph Backend
        GAS
    end

    AuthCubit --> IAuthService
    GasAuthService --> AuthSessionRepo
    GasAuthService --> GAS
```

---

## 認證流程

```mermaid
sequenceDiagram
    App->>Auth: login(email, pw)
    Auth->>GAS: POST /auth/login
    GAS-->>Auth: {token, user}
    Auth->>Session: save(token, user)
    Auth-->>App: success
```

---

## 離線認證

```mermaid
flowchart TD
    Start([啟動]) --> Net{網路?}
    Net -->|Yes| Online[Server 驗證]
    Net -->|No| Cache{有快取?}
    Cache -->|Yes| Grace{7天內?}
    Grace -->|Yes| Offline[離線模式]
    Grace -->|No| Login[重新登入]
    Cache -->|No| Login
    Online --> Full[完整功能]
    Offline --> Limited[僅讀取]
```

---

## Email 驗證流程

1. 註冊 → GAS 生成 6 位數驗證碼 (30分鐘有效)
2. `MailApp.sendEmail` 發送
3. `VerificationScreen` 輸入驗證碼
4. `auth_verify_email` API 驗證
5. `is_verified = true`

---

## Token 設計

| Token    | 有效期 | 用途         |
| :------- | :----: | :----------- |
| Access   | 1 小時 | API 授權     |
| Refresh  | 30 天  | 換取新 Token |
| 離線寬限 |  7 天  | 離線存取     |

---

## 核心介面

```dart
abstract class IAuthService {
  Future<AuthResult> login({required String email, required String password});
  Future<AuthResult> register({required String email, required String password, required String displayName});
  Future<AuthResult> validateSession();
  Future<void> logout();
  Future<String?> getAccessToken();
}
```

---

## 遷移至 Firebase

```dart
// lib/core/di.dart
getIt.registerLazySingleton<IAuthService>(
  () => FirebaseAuthService(), // 只需改這行
);
```
