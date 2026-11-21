param([string]$target)

switch ($target) {
    # === 📦 資料庫 / Docker (Database) ===
    { $_ -eq "dev-db" -or $_ -eq "11" } {
        Write-Host "[11] 啟動本地 PostgreSQL..." -ForegroundColor Cyan
        docker compose up -d db
    }
    { $_ -eq "db-migrate" -or $_ -eq "12" } {
        Write-Host "[12] 套用資料庫 schema (需為空資料庫，go run ./cmd/migrate)..." -ForegroundColor Cyan
        Set-Location backend
        go run ./cmd/migrate
        Set-Location ..
    }
    { $_ -eq "docker-migrate" -or $_ -eq "13" } {
        Write-Host "[13] 以 Docker 套用資料庫 schema (compose migrate)..." -ForegroundColor Cyan
        docker compose --profile migrate run --rm migrate
    }
    { $_ -eq "docker-api" -or $_ -eq "14" } {
        Write-Host "[14] 以 Docker 建置並啟動後端 API (compose api)..." -ForegroundColor Cyan
        docker compose --profile api up --build api
    }

    # === ⚙️ 後端 (Go API) ===
    { $_ -eq "dev-api" -or $_ -eq "21" } {
        Write-Host "[21] 啟動 Go Backend..." -ForegroundColor Cyan
        Set-Location backend
        go run ./cmd/api
        Set-Location ..
    }
    { $_ -eq "api-test" -or $_ -eq "22" } {
        Write-Host "[22] 執行後端測試..." -ForegroundColor Cyan
        Set-Location backend
        go test ./...
        Set-Location ..
    }
    { $_ -eq "api-vet" -or $_ -eq "23" } {
        Write-Host "[23] 後端 go vet..." -ForegroundColor Cyan
        Set-Location backend
        go vet ./...
        Set-Location ..
    }
    { $_ -eq "api-gen" -or $_ -eq "24" } {
        Write-Host "[24] 重新產生後端程式碼 (oapi-codegen 與 sqlc)..." -ForegroundColor Cyan
        Set-Location backend
        Set-Location api
        go run github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.8.2 --config=oapi-codegen.yaml openapi.yaml
        Set-Location ..
        go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1 generate
        Set-Location ..
    }

    # === 📱 前端 (Flutter App) ===
    { $_ -eq "app-get" -or $_ -eq "31" } {
        Write-Host "[31] 安裝 Flutter 依賴..." -ForegroundColor Cyan
        Set-Location app
        flutter pub get
        Set-Location ..
    }
    { $_ -eq "app-gen" -or $_ -eq "32" } {
        Write-Host "[32] 重新產生 Flutter 程式碼..." -ForegroundColor Cyan
        Set-Location app
        dart run build_runner build --delete-conflicting-outputs
        Set-Location ..
    }
    { $_ -eq "app-test" -or $_ -eq "33" } {
        Write-Host "[33] 執行 Flutter 測試..." -ForegroundColor Cyan
        Set-Location app
        flutter test
        Set-Location ..
    }
    { $_ -eq "app-analyze" -or $_ -eq "34" } {
        Write-Host "[34] Flutter 靜態分析..." -ForegroundColor Cyan
        Set-Location app
        flutter analyze
        Set-Location ..
    }
    { $_ -eq "app-format" -or $_ -eq "35" } {
        Write-Host "[35] 格式化 Flutter 程式碼..." -ForegroundColor Cyan
        Set-Location app
        dart format . -l 120
        Set-Location ..
    }
    { $_ -eq "dev-app" -or $_ -eq "36" } {
        Write-Host "[36] 啟動 Flutter App (預設裝置)..." -ForegroundColor Cyan
        Set-Location app
        flutter run --dart-define-from-file=.env.dev
        Set-Location ..
    }

    # === 🚀 打包部署 (Build) ===
    { $_ -eq "build-apk" -or $_ -eq "41" } {
        Write-Host "[41] 打包 Flutter APK (Prod)..." -ForegroundColor Cyan
        Set-Location app
        flutter build apk --dart-define-from-file=.env.prod
        Set-Location ..
    }
    { $_ -eq "build-appbundle" -or $_ -eq "42" } {
        Write-Host "[42] 打包 Flutter AppBundle (Prod)..." -ForegroundColor Cyan
        Set-Location app
        flutter build appbundle --release --dart-define-from-file=.env.prod
        Set-Location ..
    }

    default {
        Write-Host "請提供一個目標 (target) 或是對應的數字。" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "=== 📦 資料庫 / Docker ===" -ForegroundColor DarkCyan
        Write-Host "  [11] dev-db          - 啟動本地 PostgreSQL"
        Write-Host "  [12] db-migrate      - 套用資料庫 schema (go run，需為空資料庫)"
        Write-Host "  [13] docker-migrate  - 以 Docker 套用資料庫 schema"
        Write-Host "  [14] docker-api      - 以 Docker 建置並啟動後端 API"
        Write-Host ""

        Write-Host "=== ⚙️ 後端 (Go API) ===" -ForegroundColor DarkCyan
        Write-Host "  [21] dev-api         - 啟動 Go Backend"
        Write-Host "  [22] api-test        - 執行後端測試"
        Write-Host "  [23] api-vet         - 後端 go vet"
        Write-Host "  [24] api-gen         - 重新產生後端程式碼 (oapi-codegen / sqlc)"
        Write-Host ""

        Write-Host "=== 📱 前端 (Flutter App) ===" -ForegroundColor DarkCyan
        Write-Host "  [31] app-get         - 安裝 Flutter 依賴"
        Write-Host "  [32] app-gen         - 重新產生 Flutter 程式碼"
        Write-Host "  [33] app-test        - 執行 Flutter 測試"
        Write-Host "  [34] app-analyze     - Flutter 靜態分析"
        Write-Host "  [35] app-format      - 格式化 Flutter 程式碼"
        Write-Host "  [36] dev-app         - 啟動 Flutter App (預設裝置)"
        Write-Host ""

        Write-Host "=== 🚀 打包部署 (Build) ===" -ForegroundColor DarkCyan
        Write-Host "  [41] build-apk       - 打包 Flutter APK (Prod)"
        Write-Host "  [42] build-appbundle - 打包 Flutter AppBundle (Prod)"
        Write-Host ""

        Write-Host "💡 範例: .\tasks.ps1 36" -ForegroundColor Green
    }
}
