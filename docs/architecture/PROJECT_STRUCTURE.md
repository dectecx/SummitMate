# 專案結構 (Project Structure)

```
lib/
├── app.dart                           # App 根元件 (MaterialApp 設定)
├── main.dart                          # 程式進入點
│
├── core/                              # 核心工具層
│   ├── config/                        # 配置
│   │   └── env_config.dart            # 環境變數配置
│   ├── constants/                     # 常數子目錄
│   ├── di/                            # 依賴注入 (Injectable)
│   │   ├── injection.dart             # 自動化 DI 設定
│   │   └── modules.dart               # 外部套件註冊
│   ├── enums/                         # 領域通用列舉
│   ├── error/                         # 錯誤處理
│   │   ├── app_error_handler.dart     # 全域錯誤處理
│   │   └── result.dart                # Result<T, E> 型別
│   ├── extensions.dart                # Dart 擴展方法
│   ├── theme/                         # 主題定義
│   │   ├── app_theme.dart             # 主題工廠
│   │   └── theme_provider.dart        # 主題狀態管理
│   └── utils/                         # 共用工具
│
├── data/                              # 資料層
│   ├── api/                           # API 層 (Retrofit)
│   │   ├── models/                    # API DTO (Freezed)
│   │   ├── services/                  # Retrofit API 端點定義
│   │   └── mappers/                   # API <-> Domain 模型轉換層
│   ├── datasources/                   # 資料來源層 (Offline-First)
│   │   ├── interfaces/                # DataSource 介面
│   │   ├── local/                     # 本地儲存實作 (Drift DAOs)
│   │   └── remote/                    # 遠端 API 實作
│   ├── models/                        # 本地資料表模型 (Drift / Freezed)
│   └── repositories/                  # Repository 層 (實作 Domain 介面)
│       └── *.dart                     # Repository 具體實作
│
├── domain/                            # 領域層 (業務邏輯與實體)
│   ├── entities/                      # 領域實體 (Freezed Immutable Models)
│   ├── interfaces/                    # 服務與 Repository 介面定義
│   └── failures/                      # 領域失敗類型 (Failure Enum)
│
├── infrastructure/                    # 基礎設施層 (外部服務實作)
│   ├── database/                      # 本地資料庫管理
│   │   └── app_database.dart          # Drift SQLite 資料庫入口
│   ├── clients/                       # HTTP 客戶端
│   │   ├── api_client.dart            # Go API REST 客戶端 (Dio)
│   │   └── network_aware_client.dart  # 離線攔截裝飾器
│   ├── interceptors/                  # Dio 攔截器
│   │   └── auth_interceptor.dart      # 認證與 Refresh Token 攔截
│   ├── services/                      # 核心服務實作
│   │   ├── auth_service.dart          # 會員認證 (IAuthService)
│   │   ├── sync_service.dart          # 雙向同步 (ISyncService)
│   │   └── ad_service.dart            # 廣告服務
│   ├── tools/                         # 工具服務
│   │   ├── log_service.dart           # 日誌與上傳
│   │   └── usage_tracking_service.dart# 系統監控
│   └── observers/                     # Bloc 全域觀察器
│
└── presentation/                      # 表現層
    ├── cubits/                        # 狀態管理 (Cubit)
    │   ├── auth/                      # 認證 (AuthCubit)
    │   ├── sync/                      # 同步 (SyncCubit)
    │   ├── trip/                      # 行程 (TripCubit)
    │   └── ...                        # 其他模組
    ├── screens/                       # 畫面元件
    │   ├── main_navigation_screen.dart
    │   └── ...
    └── widgets/                       # 可重用 UI 元件
```

---

## Backend 結構 (Go)

```
backend/
├── cmd/                               # 執行入口
│   ├── api/
│   │   └── main.go                    # API Server 入口
│   ├── migrate/
│   │   └── main.go                    # DB Migration 工具
│   └── weatherjob/
│       └── main.go                    # 天氣 ETL CLI
│
├── api/                               # OpenAPI 生成碼
│   ├── openapi.yaml                   # API 規格定義
│   └── gen.go                         # oapi-codegen 產生
│
├── internal/                          # 內部套件 (不可外部引用)
│   ├── auth/                          # 認證領域 (bcrypt + verification)
│   │   ├── tokens/                    # JWT 簽發與驗證 (TokenManager)
│   │   └── mocks/                     # 測試 Mock
│   ├── trip/                          # 行程領域 (含 Gear/Meals/MealPlanDays/Members/Itinerary)
│   │   └── mocks/
│   ├── library/                       # 個人裝備庫 / 食物庫 (Gear/Meal Libraries)
│   ├── gearset/                       # 雲端裝備組合 (Gear Cloud)
│   ├── interaction/                   # 互動領域 (Polls, Messages)
│   ├── favorite/                      # 收藏領域
│   ├── groupevent/                    # 揪團領域
│   ├── weather/                       # 天氣領域 (CWA ETL 查詢)
│   ├── flag/                          # 系統旗標 (Feature Flags)
│   ├── log/                           # 系統日誌領域
│   ├── heartbeat/                     # 系統監控領域
│   ├── common/                        # 共享工具 (apiutil, ptrutil)
│   ├── middleware/                    # Chi 中介層 (JWT, CORS, RequestLogger)
│   ├── logger/                        # slog 日誌初始化
│   ├── config/                        # 環境變數設定
│   ├── database/                      # 連線池與 Migration 執行
│   ├── app/                           # 應用層 (啟動與路由分配)
│   │   └── api/                       # API 轉接層 (Adapters, Server 聚合)
│   └── apperror/                      # 錯誤碼定義
│
├── pkg/                               # 可重用套件 (可外部引用)
│   ├── cache/                         # 快取抽象 (Memory / Redis)
│   └── email/                         # SMTP 寄信服務
│
├── migrations/                        # SQL Migration 檔案
├── tests/                             # E2E 測試
├── Dockerfile                         # Multi-stage 建置
├── go.mod
└── go.sum
```

---

## 分層架構

### Frontend (Flutter)

| Layer              | 職責                 | 位置                      |
| :----------------- | :------------------- | :------------------------ |
| **Presentation**   | UI, 狀態管理 (Cubit) | `app/lib/presentation/`   |
| **Domain**         | 業務邏輯實體與介面   | `app/lib/domain/`         |
| **Infrastructure** | 外部服務實作與 DB    | `app/lib/infrastructure/` |
| **Data**           | API, Drift DAOs      | `app/lib/data/`           |
| **Core**           | 共用工具, DI         | `app/lib/core/`           |

### Backend (Go)

| Layer          | 職責                    | 位置                         |
| :------------- | :---------------------- | :--------------------------- |
| **Adapter**    | API 路由轉接, DTO 映射  | `backend/internal/app/api/`  |
| **Handler**    | 領域 Request/Response   | `backend/internal/<domain>/` |
| **Service**    | 商業邏輯                | `backend/internal/<domain>/` |
| **Repository** | 資料存取 (PostgreSQL)   | `backend/internal/<domain>/` |
| **Domain**     | 業務實體與規則          | `backend/internal/<domain>/`                       |
| **Common**     | 共享工具 (apiutil, ptrutil) | `backend/internal/common/`                     |
| **Middleware** | JWT / CORS / 日誌中介層 | `backend/internal/middleware/`                     |
| **Pkg**        | 可重用套件 (cache, email) | `backend/pkg/`                                   |
| **App**        | 應用程序啟動與路由聚合  | `backend/internal/app/`                            |
