---
name: go-backend-standard
description: Enforces Go backend DDD layering, OpenAPI spec-first workflow, transaction boundaries, and unit testing standards.
---

# Go Backend DDD Architecture & Development Standards

## Overview

This skill defines the Domain-Driven Design (DDD) layer boundaries, API consistency workflow, and testing standards for the Go backend (`backend/`).

## Architectural Layers & Responsibilities

The backend enforces a strict three-tier architecture within each domain (`backend/internal/<domain>/`):

```
HTTP Request
     │
     ▼
┌──────────────┐   1. Parse & validate request parameters
│   Handler    │   2. Convert DTO <-> Domain model
└──────┬───────┘   3. Invoke Service method and format HTTP response
       │
       ▼
┌──────────────┐   1. Execute business logic & domain validations
│   Service    │   2. Manage transaction boundaries (`pgx.Tx`)
└──────┬───────┘   3. Coordinate one or more Repositories
       │
       ▼
┌──────────────┐   1. Execute raw SQL queries via `pgxpool`
│  Repository  │   2. Map SQL rows into Domain/DB structs
└──────────────┘   3. Handle database-specific errors
```

### Layer Constraints

- **No Cross-Layer Bypasses**: Handlers must never call Repositories directly or interact with database drivers.
- **DTO Isolation**: API transport DTOs generated from OpenAPI must not leak into the Repository layer.
- **Transaction Ownership**: Transactions (`pgx.Tx`) must be initiated and coordinated at the Service layer, not inside individual Repository methods.

## Spec-First Development Workflow

All API additions or modifications must adhere to the Spec-First workflow:

1. **Edit OpenAPI Specification**: Update endpoints, request bodies, and responses in `backend/api/openapi.yaml`.
2. **Generate Code**: Run `go generate ./...` in `backend/` to regenerate server interfaces and models.
3. **Implement Domain Layers**:
   - Update Repository interface and SQL implementation.
   - Update Service interface and business logic.
   - Update Handler to bind request and invoke Service.
4. **Register Router**: Ensure new endpoints are mounted in `backend/internal/app/api/`.
5. **Write Unit Tests**: Cover Service and Repository layers with automated tests.

## Initial Development Phase Database Convention

- During the initial development phase, do **NOT** create new incremental migration files (e.g., `000002_...`).
- All schema modifications (tables, columns, indexes, foreign keys) must be applied directly to `backend/migrations/000001_init_schema.up.sql` (and `.down.sql`).
- Apply migrations locally using: `go run cmd/migrate/main.go -action up`.

## Testing Standards

- **Service Layer**: Write unit tests using `testify/mock` to mock Repositories and verify business logic branches and error handling.
- **Repository Layer**: Test SQL queries and row mapping against mocked database connections using `pgxmock` or isolated PostgreSQL integration containers.
- **Filename Convention**: Test files must reside alongside the code being tested (e.g., `service_test.go`, `repository_test.go`).
