# AGENTS.md - SummitMate Engineering & AI Guidelines

> Operational constraints and standards for AI coding assistants and developers working on SummitMate.
> The project is being **rebuilt**. Old code, docs and skills live under `legacy/` as read-only reference.

---

## 1. Project Overview & Tech Stack

SummitMate is an **Offline-First** mountain trekking and trip management app (iOS, Android) with a Go backend. Web/PWA is not supported in the first version.

- **Frontend (`app/`)**: Flutter (Dart 3.x), Riverpod (state + DI), go_router, Drift (SQLite), Dio, json_serializable, flutter_map. Feature-first folders (`ui / data / domain` per feature, shared code in `core/`).
- **Backend (`backend/`)**: Go, Chi, pgx + sqlc, PostgreSQL, OpenAPI 3 spec-first (`oapi-codegen`). Handler -> Service -> Repository.
- **Legacy (`legacy/`)**: `app_legacy/`, `backend_legacy/`, `docs/`, `skills/`. Reference only; do not edit or build from it.

---

## 2. Single Source of Truth

- **Database schema**: `backend/migrations/000001_init_schema.up.sql`
- **API contract**: `backend/api/openapi.yaml`
- **Design & decisions**: `docs/` (start at `docs/README.md`): tech decisions, onboarding/navigation, data/sync/auth.

---

## 3. Strict Operating Rules (Non-Negotiable)

1. **No autonomous decision-making**: do not make unilateral architectural choices, breaking schema updates, or trade-off decisions. Ask and get explicit confirmation first.
2. **Initial development phase**:
   - Backend SQL: do **not** add incremental migration files; edit `000001_init_schema.up.sql` directly.
   - Drift: do **not** bump `schemaVersion` or write `onUpgrade`; edit table definitions and regenerate.
   - Add new fields/parameters in their semantically logical position, not forced to the end.
   - **End-to-end consistency**: when changing domain logic or API contracts, update the whole chain: OpenAPI -> Go -> Flutter -> tests.
3. **Data access**: UI reads only from local Drift streams. Offline-first writes go through a repository that writes the row and the `outbox` entry in one transaction. Never track sync state per row. See `docs/architecture/DATA_SYNC_AUTH.md`.
4. **Go layering**: Handlers never call Repositories directly. Spec-first: edit `openapi.yaml` -> regenerate -> implement -> test.

---

## 4. Essential Commands

### Frontend (`app/`)
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format . -l 120`
- `flutter test`
- `flutter run`

### Backend (`backend/`)
- `go run ./cmd/api`
- `go test ./...`
- `go vet ./...`
- Generators (`oapi-codegen`, `sqlc`) are installed in `~/go/bin`; call them by full path or via `go generate`.

---

## 5. Skills

Project skills live in `.claude/skills/`: `go-backend-standard`, `go-code-review`.
Flutter-related skills from the old project were moved to `legacy/skills/` and will be rewritten once the new app structure has real code.
