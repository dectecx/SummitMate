# SummitMate 🏔️

> 嘉明湖登山行程助手 — Mono-repo (Flutter App + Go Backend)

## 專案結構

```
SummitMate/
├── app/           # Flutter 前端 (Mobile / Web) → 詳見 app/README.md
├── backend/       # Go 後端 (Chi + PostgreSQL)
├── gas/           # 舊 GAS 後端 (參考用)
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

### Go Backend (開發中)
```bash
cd backend
go run cmd/api/main.go
```

### 本地資料庫
```bash
docker compose up -d db
```

## 詳細說明

- **Flutter App 文件**: [app/README.md](app/README.md)
- **設計文件**: [docs/](docs/README.md)
