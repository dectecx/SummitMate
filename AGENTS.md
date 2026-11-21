# AGENTS.md - SummitMate Engineering & AI Guidelines

> Universal operational constraints, architectural standards, and development workflows for AI coding assistants and developers working on the SummitMate codebase.

---

## 1. Project Overview & Tech Stack

SummitMate is an **Offline-First** mountain trekking and trip management system with cross-platform clients (iOS, Android, Web/PWA) and a Go backend.

- **Frontend (`app/`)**:
  - **Framework**: Flutter (Dart 3.x)
  - **Architecture**: DDD / Clean Architecture (`presentation/`, `domain/`, `data/`, `infrastructure/`, `core/`)
  - **State Management**: `flutter_bloc` (Cubit)
  - **Local Database**: Drift (SQLite) with Web Worker support
  - **Networking & Serialization**: Retrofit, Dio, Freezed, JSON Serializable
  - **Dependency Injection**: Injectable & GetIt
- **Backend (`backend/`)**:
  - **Language & Runtime**: Go 1.26
  - **Web Framework**: Chi Router
  - **Database & Storage**: PostgreSQL 18 with `pgx` connection pooling
  - **Architecture**: Domain-Driven Design (DDD) (`internal/<domain>/`: Handler -> Service -> Repository)
  - **API Specification**: OpenAPI 3.0.3 Spec-First (`backend/api/openapi.yaml`) with `oapi-codegen`

---

## 2. Single Source of Truth (SSOT)

- **Database Schema**: `backend/migrations/000001_init_schema.up.sql` (mirrored in `docs/database/SCHEMA.md`).
- **API Contracts**: `backend/api/openapi.yaml` (mirrored in `docs/api/CONTRACT.md`).
- **Architecture Documentation**: Detailed system guides reside in `docs/architecture/` (`OVERVIEW.md`, `PROJECT_STRUCTURE.md`, `OFFLINE.md`, `AUTH.md`).

---

## 3. Strict Operating Rules (Non-Negotiable)

1. **No Autonomous Decision-Making**:
   - Do not make unilateral architectural choices, breaking schema updates, or trade-off decisions.
   - Always request clarification and obtain explicit confirmation before proceeding with architectural or design changes.
2. **Initial Development Phase Conventions**:
   - The project is in active initial development (First Version).
   - **Backend SQL Migrations**: Do **NOT** create incremental migration files (e.g., `000002_*.sql`). All schema adjustments (new columns, foreign keys, table modifications) must be made directly in `backend/migrations/000001_init_schema.up.sql`.
   - **Drift SQLite Schema**: Do **NOT** increment `schemaVersion` or write incremental `onUpgrade` migrations. Directly modify Drift Table definitions in `app/lib/data/models/*_table.dart` and rebuild.
   - **Field & Parameter Ordering**: Add new fields, function parameters, or struct properties in their semantically most logical position (grouped by business logic), rather than forcing them to the end.
   - **End-to-End Consistency**: When modifying domain logic or API contracts, update the full chain: OpenAPI spec -> Go models/handlers/services/repos -> Flutter models/mappers/repositories/cubits -> Tests.

---

## 4. Architecture & Data Access Standards

### A. Flutter Data Access (Three Sync Modes)
All UI and Cubit operations **must** call the feature's `Repository`. Cubits must never decide between remote/local sources or check connectivity directly.

| Mode | Read Behavior | Write Behavior | Remote Handling | Examples |
| :--- | :--- | :--- | :--- | :--- |
| **A. OnlineOnly** | Direct remote call | Direct remote call | Inside Repo via `online()` guard | User search, cloud gear library browsing |
| **B. CachedRead + OnlineWrite** | Return local cache (background `refresh()` when online) | Remote write directly; update local cache on success | Inside Repo via `online()` and `cachedRead()` | Polls, messages, social group interactions |
| **C. OfflineFirst** | Read local Drift SQLite | Write local Drift SQLite with `syncStatus=pending*` | Managed by `SyncEngine` + `ISyncAdapter` in background. Repo **never** blocks on network. | Trips, itinerary nodes, gear lists, favorites |

### B. Go Backend DDD Layering
- **Strict Layer Hierarchy**: `Handler` (DTO validation & mapping) -> `Service` (Business rules & transactions) -> `Repository` (SQL execution & mapping).
- **No Layer Skipping**: Handlers must never call Repositories directly.
- **Spec-First Flow**: Edit `backend/api/openapi.yaml` -> Run `go generate ./...` -> Implement Service/Repository/Handler -> Add unit tests with `testify` / `pgxmock`.

---

## 5. Essential Commands

### Frontend (`app/`)
- **Install dependencies**: `flutter pub get`
- **Code generation (Freezed / Drift / Retrofit)**: `dart run build_runner build --delete-conflicting-outputs`
- **Code format**: `dart format . -l 120`
- **Unit & widget tests**: `flutter test`
- **Run mobile app (Dev environment)**: `flutter run --dart-define-from-file=.env.dev`
- **Run mobile app (Prod environment)**: `flutter run --dart-define-from-file=.env.prod`
- **Run Chrome web app**: `flutter run -d chrome --web-port 54263 --dart-define-from-file=.env.dev`
- **Launch Android emulator**: `flutter emulators --launch <emulator_id>`
- **Build APK (Dev debug)**: `flutter build apk --debug --dart-define-from-file=.env.dev`
- **Build APK (Prod release)**: `flutter build apk --release --dart-define-from-file=.env.prod`
- **Build AppBundle (Prod release)**: `flutter build appbundle --release --dart-define-from-file=.env.prod`

### Backend (`backend/`)
- **Run API server**: `go run cmd/api/main.go`
- **Run unit & integration tests**: `go test ./...`
- **Generate OpenAPI code**: `go generate ./...`
- **Apply local database migrations**: `go run ./cmd/migrate up` (run inside `backend/`)
- **Rollback database migrations**: `go run ./cmd/migrate down` (run inside `backend/`)

---

## 6. Skills Directory Reference

Reusable engineering guidelines and review standards are maintained under `.claude/skills/` (and mirrored via junction to `.agents/skills/`):

- **`flutter-offline-first-sync`**: Three sync modes and background sync engine architecture.
- **`drift-database-management`**: SQLite table modeling, initial dev conventions, and production migration policies.
- **`flutter-api-layer`**: Retrofit, Freezed DTOs, UTC datetime converters, and domain mappers.
- **`go-backend-standard`**: Go DDD layering, transaction boundaries, and OpenAPI synchronization.
- **`flutter-code-review`**: Comprehensive Flutter review (DDD boundaries, Cubit memory leaks, screen lifecycles, widget rendering).
- **`go-code-review`**: Comprehensive Go review (SQL injection, auth/JWT security, N+1 queries, concurrency safety).
- **`env-deployment`**: Environment variables (`.env`), containerization (Docker), and cloud platform deployment alignment (Netlify / GCP).
