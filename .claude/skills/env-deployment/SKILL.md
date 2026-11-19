---
name: env-deployment
description: Manages environment configuration, cloud deployment alignment (Docker, GCP Cloud Run, Netlify), and documentation synchronization across Flutter and Go.
---

# Environment Configuration & Deployment Standards

## Overview

This skill defines standards for managing environment variables, containerization, deployment platforms, and documentation synchronization across the SummitMate stack.

---

## 1. Environment Variable Architecture

### A. Flutter Frontend (`app/`)
- **Central Configuration**: Managed through `app/lib/core/config/env_config.dart`.
- **Environment Files**:
  - `app/.env.dev`: Local development against local or staging APIs.
  - `app/.env.prod`: Production builds connecting to production cloud endpoints.
- **Rules**:
  - Never commit raw `.env` files containing production secrets to version control.
  - New configuration flags added to `env_config.dart` must exist in both `.env.dev` and `.env.prod`.
  - Pass environments at build/run time via `--dart-define-from-file=.env.<env>`.

### B. Go Backend (`backend/`)
- **Central Configuration**: Managed in `backend/internal/config/config.go`.
- **Validation**:
  - The configuration loader must validate all mandatory variables (`DB_URL`, `JWT_SECRET`, `PORT`) at server startup.
  - Missing mandatory variables must trigger a fatal initialization error rather than falling back to unsafe defaults.
- **Secret Management**:
  - Sensitive values in production (database credentials, JWT signing keys) are injected via GCP Secret Manager or environment variables in GCP Cloud Run.

---

## 2. Deployment & Infrastructure Alignment

### A. Go Backend (Docker & GCP Cloud Run)
- **Container Build**: `backend/Dockerfile` utilizes multi-stage builds (builder stage with Go compiler, lightweight scratch/alpine runtime stage).
- **Migration Execution**: Database migrations run via CLI tool `cmd/migrate` before service traffic routes to new containers.
- **GCP Resources**: Infrastructure initialization details are documented in `_local_docs/other/gcp-setup.md`.

### B. Flutter Web & PWA (Netlify)
- **Routing & Headers**: `app/netlify.toml` configures SPA redirects (`/* /index.html 200`) and security headers.
- **PWA Manifest**: `app/web/manifest.json` configures application name, icons, and display mode (`standalone`).

---

## 3. Documentation & Code Synchronization

Whenever core architectural boundaries, API contracts, or schemas change:

- **Database Changes**: Update `backend/migrations/000001_init_schema.up.sql` and mirror changes in `docs/database/SCHEMA.md`.
- **API Contract Changes**: Update `backend/api/openapi.yaml` and mirror changes in `docs/api/CONTRACT.md`.
- **Architecture Updates**: When adjusting directory structure or adding core services, update `docs/architecture/PROJECT_STRUCTURE.md` and `docs/architecture/OVERVIEW.md`.
- **Commit Prefix**: Documentation updates must use the `docs:` Conventional Commit prefix.
