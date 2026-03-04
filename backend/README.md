# SummitMate Backend

## 概述 (Overview)

SummitMate 後端 API 服務，為行動端 (Flutter) 提供 RESTful API。採用 **Spec-First** 開發模式：先定義 OpenAPI 規格，再自動產生 Go 伺服器程式碼。

## 技術堆疊 (Tech Stack)

| 項目 | 技術 | 說明 |
| :--- | :--- | :--- |
| 語言 | **Go 1.25** | 高效能、低記憶體 |
| Web 框架 | **Chi** | 輕量、相容 stdlib |
| 資料庫 | **PostgreSQL** | 關聯式資料、ACID |
| API 規格 | **OpenAPI 3.0.3** | Spec-First (YAML) |
| Code Gen | **oapi-codegen** | 從 spec 產生 ServerInterface + Models |
| API 文件 | **Scalar** | 現代化互動式 API Reference |
| 容器化 | **Docker** | 多階段建置 |

## 目錄結構 (Directory Structure)

```
backend/
├── api/
│   ├── openapi.yaml        # OpenAPI 3.0 規格 (Single Source of Truth)
│   ├── oapi-codegen.yaml   # Code Gen 設定
│   ├── gen.go              # 自動產生 (DO NOT EDIT)
│   └── generate.go         # //go:generate 指令
├── cmd/
│   └── api/
│       └── main.go         # 應用程式進入點
├── internal/               # 內部套件 (不對外開放)
│   ├── handler/            # HTTP Handlers (實作 ServerInterface)
│   ├── service/            # Business Logic
│   ├── repository/         # DB Access
│   └── model/              # Domain Models
├── migrations/             # SQL Migrations
├── Dockerfile              # 多階段建置
├── go.mod
└── go.sum
```

## 快速上手 (Getting Started)

### 前置需求

- Go 1.25+
- Docker & Docker Compose (用於 PostgreSQL)

### 啟動開發伺服器

```bash
cd backend

# 1. 啟動 PostgreSQL (從專案根目錄)
docker compose up -d db

# 2. 產生 API 程式碼 (如有修改 openapi.yaml)
go generate ./api/...

# 3. 啟動伺服器
go run ./cmd/api
```

伺服器啟動後：
- 📖 **API 文件**：http://localhost:8080/docs
- 🔗 **OpenAPI Spec**：http://localhost:8080/openapi.json
- ❤️ **Health Check**：http://localhost:8080/api/v1/health

## 開發流程 (Development Workflow)

### 新增 API Endpoint

1. **編輯規格**：修改 `api/openapi.yaml`，新增 path 和 schema
2. **產生程式碼**：
   ```bash
   go generate ./api/...
   ```
3. **實作 Handler**：在 `cmd/api/main.go` (或 `internal/handler/`) 實作新的 `ServerInterface` 方法
4. **驗證**：瀏覽 http://localhost:8080/docs 確認新 endpoint

### 建置 (Build)

```bash
# 本地建置
go build -o bin/api ./cmd/api

# Docker 建置
docker build -t summitmate-api .
```

## 部署 (Deployment)

- **目標平台**：GCP e2-micro (Free Tier)
- **資料庫**：Supabase PostgreSQL (Free Tier, 500MB)
- 詳細部署指南待 Phase 4 完成後補充
