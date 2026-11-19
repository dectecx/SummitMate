---
name: go-code-review
description: Comprehensive code review checklist for Go backend security, database SQL performance, DDD layer boundaries, and concurrency safety.
---

# Go Backend Code Review Standards & Checklist

## Overview

This skill defines the technical review criteria for the Go backend (`backend/`), covering security vulnerabilities, database performance, architecture layering, and concurrency safety.

---

## 1. Security & Authorization

### Checklist

- [ ] **SQL Injection Prevention**: All SQL queries must use parameterized placeholders (`$1, $2`). String concatenation or `fmt.Sprintf` in SQL construction is strictly prohibited.
- [ ] **JWT Verification**: JWT parser must enforce explicit algorithm whitelisting (e.g., `jwt.WithValidMethods([]string{"HS256"})`) and check `exp` expiration claims.
- [ ] **IDOR & Ownership Verification**: Domain services must verify that the requesting authenticated user owns or has the required role on target resources (e.g., trips, gear lists).
- [ ] **Sensitive Data Scrubbing**: Passwords, auth tokens, and encryption keys must never be logged to stdout or logging services.
- [ ] **Password Hashing**: Passwords must be hashed using `bcrypt` with cost >= 10 before persistence.

```go
// ❌ Incorrect: SQL injection vulnerability via string concatenation
query := fmt.Sprintf("SELECT * FROM trips WHERE id = '%s'", tripID)

// ✅ Correct: Parameterized query
query := "SELECT * FROM trips WHERE id = $1"
row := db.QueryRow(ctx, query, tripID)
```

---

## 2. Database & SQL Performance

### Checklist

- [ ] **N+1 Query Avoidance**: Queries inside loops are prohibited. Fetch associated collections using `WHERE id = ANY($1)` or SQL joins.
- [ ] **Atomic Transactions**: Multi-step database mutations across multiple tables must execute within an explicit database transaction (`pgx.Tx`).
- [ ] **Resource Release**: Every `db.Query()` call must be immediately paired with `defer rows.Close()`, and `rows.Err()` must be checked after iteration.
- [ ] **Index Coverage**: Verify that all foreign keys and frequently filtered columns (`user_id`, `trip_id`, `created_at`) have corresponding indexes in `backend/migrations/000001_init_schema.up.sql`.

```go
// ❌ Incorrect: Potential connection leak
rows, err := db.Query(ctx, query, tripID)
if err != nil {
    return nil, err
}
// Missing defer rows.Close()

// ✅ Correct: Explicit deferred close
rows, err := db.Query(ctx, query, tripID)
if err != nil {
    return nil, err
}
defer rows.Close()
```

---

## 3. Architecture & OpenAPI Consistency

### Checklist

- [ ] **Strict Layer Hierarchy**: Handlers must only call Services; Services must only call Repositories. Handlers must never invoke Repositories or execute raw SQL directly.
- [ ] **OpenAPI Spec Parity**: HTTP request DTOs, response schemas, and status codes must match the contract in `backend/api/openapi.yaml`.
- [ ] **Context Propagation**: The incoming `r.Context()` from HTTP requests must be passed through Handlers and Services down to all database and network operations.
- [ ] **Unit Test Coverage**: Domain services and repositories must have accompanying `_test.go` files utilizing `pgxmock` or `testify/mock`.

---

## 4. Concurrency & Resource Safety

### Checklist

- [ ] **Goroutine Leak Prevention**: Every launched goroutine must be bounded by a cancellable `context.Context` or a deterministic termination condition.
- [ ] **Data Race Prevention**: Shared in-memory data structures must be guarded using `sync.Mutex`, `sync.RWMutex`, or atomic primitives. Run tests with `-race`.
- [ ] **Timeouts on External Calls**: Outgoing HTTP requests (e.g., weather APIs, email SMTP) must specify explicit timeouts on the `http.Client`.
- [ ] **Graceful Shutdown**: Background workers and HTTP servers must listen for termination signals (`SIGINT`, `SIGTERM`) and drain active connections.

---

## Review Output Format

When providing code review findings, structure items by severity:

```markdown
### [Severity: High/Medium/Low] File:LineRange - Short Title
- **Problem**: Objective explanation of the defect or security concern.
- **Risk**: Concrete impact (data corruption, security exploit, resource leak).
- **Remediation**: Recommended fix with a concise code example.
```
