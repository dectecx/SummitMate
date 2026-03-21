# SummitMate Backend

## 概述

SummitMate 後端 API 服務，為行動端 (Flutter) 提供 RESTful API。採用 **Spec-First** 開發模式：先定義 OpenAPI 規格，再自動產生 Go 伺服器程式碼。

## 技術堆疊

| 項目      | 技術               | 說明                                  |
| :-------- | :----------------- | :------------------------------------ |
| 語言      | **Go 1.25**        | 高效能、低記憶體                      |
| Web 框架  | **Chi**            | 輕量、相容 stdlib                     |
| 資料庫    | **PostgreSQL 18**  | 關聯式資料、ACID                      |
| DB Driver | **pgx**            | 高效能 PostgreSQL driver + 連線池     |
| DB 遷移   | **golang-migrate** | SQL-based schema migration            |
| API 規格  | **OpenAPI 3.0.3**  | Spec-First (YAML)                     |
| Code Gen  | **oapi-codegen**   | 從 spec 產生 ServerInterface + Models |
| API 文件  | **Scalar**         | 現代化互動式 API Reference            |
| 容器化    | **Docker**         | 多階段建置                            |

## 目錄結構

```
backend/
├── api/
│   ├── openapi.yaml        # OpenAPI 3.0 規格 (Single Source of Truth)
│   ├── oapi-codegen.yaml   # Code Gen 設定
│   ├── gen.go              # 自動產生 (DO NOT EDIT)
│   └── generate.go         # //go:generate 指令
├── cmd/
│   ├── api/
│   │   └── main.go         # Web API 進入點
│   ├── migrate/
│   │   └── main.go         # DB Migration CLI
│   └── weatherjob/
│       └── main.go         # 天氣 ETL 排程任務 (Standalone CLI)
│ ├── internal/               # 內部套件 (不對外開放)
│   ├── config/             # 環境變數設定
│   ├── database/           # DB 連線池 + Migration
│   ├── handler/            # HTTP Handlers (實作 ServerInterface)
│   ├── service/            # Business Logic
│   ├── repository/         # DB Access
│   └── model/              # Domain Models
├── migrations/             # SQL Migration 檔案
│   ├── 000001_init_schema.up.sql
│   └── 000001_init_schema.down.sql
├── Dockerfile              # 多階段建置
├── go.mod
└── go.sum
```

## 快速上手

### 前置需求

- Go 1.25+
- Docker & Docker Compose (用於 PostgreSQL)

### 首次設定

```bash
# 1. 啟動 PostgreSQL
docker compose up -d db

# 2. 執行資料庫遷移 (建立所有表)
cd backend
go run ./cmd/migrate up

# 3. 產生 API 程式碼 (首次或修改 openapi.yaml 後)
go generate ./api/...

# 4. 啟動 API 伺服器
go run ./cmd/api
```

### 日常開發

```bash
cd backend

# 啟動伺服器 (PostgreSQL 需已啟動且已跑過 migration)
go run ./cmd/api
```

伺服器啟動後：

- 📖 **API 文件**：http://localhost:8080/docs
- 🔗 **OpenAPI Spec**：http://localhost:8080/openapi.json
- ❤️ **Health Check**：http://localhost:8080/api/v1/health

## 資料庫遷移

Migration 使用獨立 CLI 工具，**不會在 API 啟動時自動執行**。

```bash
cd backend

# 套用所有待執行的 migration
go run ./cmd/migrate up

# 回滾最近一次 migration
go run ./cmd/migrate down

# 查看目前版本
go run ./cmd/migrate version

# 刪除所有表 (需手動確認)
go run ./cmd/migrate drop
```

### 新增 Migration

1. 在 `migrations/` 目錄新增一對檔案：
   - `000002_add_xxx.up.sql` — 正向變更
   - `000002_add_xxx.down.sql` — 回滾變更
2. 執行 `go run ./cmd/migrate up`

### 環境變數

| 變數           | 預設值                                                              | 說明                         |
| :------------- | :------------------------------------------------------------------ | :--------------------------- |
| `ENV`          | `development`                                                       | 執行環境 (`production`, `development`) |
| `PORT`         | `8080`                                                              | HTTP 監聽埠                  |
| `DATABASE_URL` | `postgres://dev:dev2026!@localhost:5432/summitmate?sslmode=disable` | PostgreSQL 連線              |
| `JWT_SECRET`   | `summitmate-dev-secret-change-in-production`                        | JWT 簽名密鑰                 |
| `CWA_API_KEY`  | (必填)                                                              | 中央氣象署 Open Data API Key |

## 定時任務

### 天氣 ETL

`cmd/weatherjob` 是一個獨立的 CLI 工具，用於從氣象署擷取登山天氣資料並更新至資料庫。

```bash
cd backend
# 執行一次天氣資料更新
CWA_API_KEY=your_key_here go run ./cmd/weatherjob
```

建議使用 cron 或其他排程工具定期執行（例如每 6 小時一次）。

## 開發流程

### 新增 API Endpoint

1. **編輯規格**：修改 `api/openapi.yaml`，新增 path 和 schema
2. **產生程式碼**：
   ```bash
   go generate ./api/...
   ```
3. **實作 Handler**：在 `internal/handler/` 實作新的 `ServerInterface` 方法
4. **驗證**：瀏覽 http://localhost:8080/docs 確認新 endpoint

### 建置

```bash
# 本地建置
go build -o bin/api ./cmd/api

# Docker 建置
docker build -t summitmate-api .
```

## 日誌與監控

系統採用 Go 標準庫 `log/slog` 進行結構化日誌記錄。日誌行為會根據 `ENV` 環境變數自動切換：

-   **開發環境 (`ENV=development`)**：
    -   格式：人類可讀的 Text 格式。
    -   輸出：同時輸出至 `stdout` (控制台) 與 `backend/logs/app.log` 檔案。
    -   用途：方便開發者在控制台即時除錯，並保留本地日誌檔案供後續查驗。
-   **正式環境 (`ENV=production`)**：
    -   格式：結構化 **JSON** 格式。
    -   輸出：僅輸出至 `stdout`。
    -   用途：符合雲端平台 (如 GCP, Azure, AWS) 的日誌收集慣例，方便集中化監控與檢索。

所有 HTTP 請求皆會自動附帶 `request_id` 與執行時長，業務邏輯層則會記錄關鍵動作 (如註冊、行程建立等) 以供追蹤使用者操作流程。

## 部署

- **目標平台**：GCP e2-micro (Free Tier)
- **資料庫**：Supabase PostgreSQL (Free Tier, 500MB)
- 詳細部署指南待 Phase 4 完成後補充
