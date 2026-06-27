# 部署指南

本文件說明 SummitMate 各元件的部署流程。

---

## 1. Go Backend

### 環境變數

連線字串由各 `DB_*` 變數於啟動時組合而成 (`postgres://<user>:<pass>@<host>:<port>/<name>?sslmode=<mode>`)，本服務**不直接讀取** `DATABASE_URL`。

#### 核心

| 變數      | 說明                                    | 預設值          |
| :-------- | :-------------------------------------- | :-------------- |
| `PORT`    | 監聽埠                                  | `8080`          |
| `ENV`     | 環境標識 (`development` / `production`) | `development`   |
| `JWT_SECRET` | JWT 簽章密鑰 (正式環境**必須**設定)  | 空字串          |
| `CWA_API_KEY` | 中央氣象署 API 授權碼 (Weather ETL) | 空字串          |
| `ALLOWED_ORIGINS` | CORS 允許來源 (逗號分隔)        | `https://summitmate-tw.netlify.app` (dev 另含 localhost) |

#### 資料庫 (PostgreSQL)

| 變數         | 說明        | 預設值        |
| :----------- | :---------- | :------------ |
| `DB_HOST`    | 主機        | `localhost`   |
| `DB_PORT`    | 埠          | `5432`        |
| `DB_USER`    | 帳號        | `dev`         |
| `DB_PASS`    | 密碼        | `dev2026!`    |
| `DB_NAME`    | 資料庫名    | `summitmate`  |
| `DB_SSLMODE` | SSL 模式    | `disable`     |

#### Email (SMTP)

| 變數           | 說明              | 預設值                                  |
| :------------- | :---------------- | :-------------------------------------- |
| `SMTP_HOST`    | SMTP 主機         | `smtp.gmail.com`                        |
| `SMTP_PORT`    | SMTP 埠           | `587`                                   |
| `SMTP_USER`    | SMTP 帳號         | 空字串                                  |
| `SMTP_PASS`    | SMTP 密碼         | 空字串                                  |
| `SMTP_FROM`    | 寄件者            | `SummitMate <noreply@summitmate.com>`   |
| `SMTP_USE_SSL` | 是否使用 SSL      | `false`                                 |

#### 快取 (Cache)

| 變數             | 說明                          | 預設值            |
| :--------------- | :---------------------------- | :---------------- |
| `CACHE_TYPE`     | 快取類型 (`memory` / `redis`) | `memory`          |
| `REDIS_ADDR`     | Redis 位址                    | `localhost:6379`  |
| `REDIS_PASSWORD` | Redis 密碼                    | 空字串            |
| `REDIS_DB`       | Redis DB 編號                 | `0`               |

### 本地開發

```bash
# 啟動 PostgreSQL
docker compose up -d db

# 執行 DB Migration
go run cmd/migrate/main.go

# 啟動 API Server
go run cmd/api/main.go
```

API 文件：http://localhost:8080/docs

### Docker 部署

```bash
# 建置映像
docker build -t summitmate-api ./backend

# 執行
docker run -p 8080:8080 \
  -e DB_HOST="your-db-host" \
  -e DB_USER="your-db-user" \
  -e DB_PASS="your-db-pass" \
  -e DB_NAME="summitmate" \
  -e DB_SSLMODE="require" \
  -e JWT_SECRET="your-prod-secret" \
  -e ENV="production" \
  summitmate-api
```

### CLI 工具

| 指令                            | 用途                               |
| :------------------------------ | :--------------------------------- |
| `go run cmd/api/main.go`        | 啟動 API Server                    |
| `go run cmd/migrate/main.go`    | 執行 DB Migration                  |
| `go run cmd/weatherjob/main.go` | 手動執行天氣 ETL (適合排程或 cron) |

### 日誌

- **Production** (`ENV=production`)：JSON 格式輸出至 stdout，適合 GCP/Azure/AWS Log Collector
- **Development** (`ENV=development`)：Text 格式同時輸出至 stdout 與 `backend/logs/app.log`

---

## 2. Flutter Web Deployment

本專案支援多種 Web 部署方式，以下列出 Netlify 與 GitHub Pages 的配置流程。

### 方式 A: Netlify (Via GitHub Actions)

此方式透過 CI/CD 自動建置並部署至 Netlify。

#### 1. Netlify 設定

1.  新增網站 (Import from Git 或 Deploy manually)。
2.  取得 **Site ID** (`Site settings` > `Site details` > `API ID`)。
3.  取得 **Access Token** (`User settings` > `Applications` > `Personal access tokens` > `New access token`)。
    - 注意：請勿建立 "OAuth application"，這不是我們要的。
    - Description 填寫 "GitHub Actions" 並設定過期時間。
    - 複製生成的 Token (以此作為 `NETLIFY_AUTH_TOKEN`)。

#### 2. GitHub Secrets 設定

於 GitHub Repository 的 `Settings` > `Secrets and variables` > `Actions` 新增以下變數：

| Name                 | Description                   |
| -------------------- | ----------------------------- |
| `NETLIFY_SITE_ID`    | Netlify Site API ID           |
| `NETLIFY_AUTH_TOKEN` | Netlify Personal Access Token |

#### 3. 觸發部署

推送程式碼至 `main` 分支即自動觸發 `.github/workflows/deploy_to_netlify.yml` 流程。

---

### 方式 B: GitHub Pages

此方式透過 `peanut` 工具建置並推送到 `gh-pages` 分支。

#### 1. 前置需求

- Flutter SDK
- Dart SDK

#### 2. 建置與推送

執行以下指令將 Web 版建置至 `gh-pages` 分支：

```bash
# 啟用 peanut
dart pub global activate peanut

# 建置 (需指定 repository 名稱作為 base-href)
dart pub global run peanut --extra-args "--base-href=/SummitMate/ --dart-define-from-file=.env.prod"

# 推送
git push origin --set-upstream gh-pages
```

#### 3. 啟用 Pages

於 GitHub Repository 的 `Settings` > `Pages` 設定：

- **Source**: Deploy from a branch
- **Branch**: `gh-pages` / `/ (root)`

---

## 3. Android Deployment

建置 Release APK：

```bash
flutter build apk --dart-define-from-file=.env.prod
```

輸出路徑：`build/app/outputs/flutter-apk/app-release.apk`

### 環境變數設定 (AdMob)

為了確保 AdMob 正確運作且不暴露 App ID，請在 CI/CD 環境或本地打包時設定以下環境變數：

| Name           | Description                         | Required | Source                         |
| -------------- | ----------------------------------- | -------- | ------------------------------ |
| `ADMOB_APP_ID` | AdMob App ID (ca-app-pub-xxxx~yyyy) | **Yes**  | CI Secret / `local.properties` |

**注意**：此變數由 Gradle (Android) / Build Phase (iOS) 讀取，並不在 `.env.prod` 中 (因為 `.env` 是被編譯進 Dart 程式碼，而 App ID 需要在 Native 層級生效)。
