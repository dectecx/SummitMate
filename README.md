# SummitMate 🏔️

> 登山行程管理應用 — Mono-repo (Flutter App + Go Backend)

## 專案結構

```
SummitMate/
├── app/           # Flutter 前端 (Mobile / Web) → 詳見 app/README.md
├── backend/       # Go 後端 (Chi + PostgreSQL) → 詳見 backend/README.md
├── gas/           # 舊 GAS 後端 (Legacy，逐步淘汰中)
├── docs/          # 專案文件
└── docker-compose.yml
```

## Quick Start

### Flutter App

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Go Backend

```bash
# 啟動 PostgreSQL
docker compose up -d db

# 執行 DB Migration
cd backend && go run cmd/migrate/main.go

# 啟動 API Server
go run cmd/api/main.go
```

API 文件：http://localhost:8080/docs

### 環境變數 (Backend)

| 變數           | 說明                         |
| :------------- | :--------------------------- |
| `DATABASE_URL` | PostgreSQL 連線字串          |
| `JWT_SECRET`   | JWT 簽章密鑰                 |
| `CWA_API_KEY`  | 中央氣象署 API 授權碼        |
| `ENV`          | `development` / `production` |

## 詳細說明

- **Flutter App 文件**: [app/README.md](app/README.md)
- **Go Backend 文件**: [backend/README.md](backend/README.md)
- **設計文件**: [docs/](docs/README.md)
