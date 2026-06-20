param([string]$target)

switch ($target) {
    # === 📦 資料庫 (Database) ===
    { $_ -eq "dev-db" -or $_ -eq "11" } {
        Write-Host "[11] 啟動本地 PostgreSQL..." -ForegroundColor Cyan
        docker compose up -d db
    }
    { $_ -eq "db-up" -or $_ -eq "12" } {
        Write-Host "[12] 執行資料庫 Migration Up..." -ForegroundColor Cyan
        Set-Location backend
        go run ./cmd/migrate up
        Set-Location ..
    }
    { $_ -eq "db-drop" -or $_ -eq "13" } {
        Write-Host "[13] 執行資料庫 Migration Drop (危險操作)..." -ForegroundColor Red
        Set-Location backend
        go run ./cmd/migrate drop
        Set-Location ..
    }

    # === ⚙️ 後端 (Go API) ===
    { $_ -eq "dev-api" -or $_ -eq "21" } {
        Write-Host "[21] 啟動 Go Backend..." -ForegroundColor Cyan
        Set-Location backend
        go run cmd/api/main.go
        Set-Location ..
    }
    { $_ -eq "api-gen" -or $_ -eq "22" } {
        Write-Host "[22] 重新產生後端 API 程式碼..." -ForegroundColor Cyan
        Set-Location backend
        go generate ./...
        Set-Location ..
    }
    { $_ -eq "mock-gen" -or $_ -eq "23" } {
        Write-Host "[23] 重新產生後端 Mocks..." -ForegroundColor Cyan
        Set-Location backend
        go generate ./...
        Set-Location ..
    }

    # === 📱 前端 (Flutter App) ===
    { $_ -eq "dev-app" -or $_ -eq "31" } {
        Write-Host "[31] 啟動 Flutter App (Web)..." -ForegroundColor Cyan
        Set-Location app
        flutter run --dart-define-from-file=.env.dev -d chrome --web-port 54263
        Set-Location ..
    }
    { $_ -eq "dev-app-mobile" -or $_ -eq "32" } {
        Write-Host "[32] 啟動 Flutter App (Mobile/預設裝置)..." -ForegroundColor Cyan
        Set-Location app
        flutter run --dart-define-from-file=.env.dev
        Set-Location ..
    }
    { $_ -eq "app-format" -or $_ -eq "33" } {
        Write-Host "[33] 格式化 Flutter 程式碼..." -ForegroundColor Cyan
        Set-Location app
        dart format . -l 120
        Set-Location ..
    }
    { $_ -eq "app-get" -or $_ -eq "34" } {
        Write-Host "[34] 安裝 Flutter 依賴..." -ForegroundColor Cyan
        Set-Location app
        flutter pub get
        Set-Location ..
    }
    { $_ -eq "app-gen" -or $_ -eq "35" } {
        Write-Host "[35] 重新產生 Flutter 程式碼..." -ForegroundColor Cyan
        Set-Location app
        dart run build_runner build --delete-conflicting-outputs
        Set-Location ..
    }
    { $_ -eq "app-worker" -or $_ -eq "36" } {
        Write-Host "[36] 編譯 Drift Web Worker..." -ForegroundColor Cyan
        Set-Location app
        dart compile js web/drift_worker.dart -o web/drift_worker.js
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
        
        Write-Host "=== 📦 資料庫 (Database) ===" -ForegroundColor DarkCyan
        Write-Host "  [11] dev-db          - 啟動本地 PostgreSQL"
        Write-Host "  [12] db-up           - 執行資料庫 Migration Up"
        Write-Host "  [13] db-drop         - 執行資料庫 Migration Drop (危險操作)" -ForegroundColor Red
        Write-Host ""
        
        Write-Host "=== ⚙️ 後端 (Go API) ===" -ForegroundColor DarkCyan
        Write-Host "  [21] dev-api         - 啟動 Go Backend"
        Write-Host "  [22] api-gen         - 重新產生後端 API 程式碼"
        Write-Host "  [23] mock-gen        - 重新產生後端 Mocks"
        Write-Host ""

        Write-Host "=== 📱 前端 (Flutter App) ===" -ForegroundColor DarkCyan
        Write-Host "  [31] dev-app         - 啟動 Flutter App (Web)"
        Write-Host "  [32] dev-app-mobile  - 啟動 Flutter App (Mobile/預設裝置)"
        Write-Host "  [33] app-format      - 格式化 Flutter 程式碼"
        Write-Host "  [34] app-get         - 安裝 Flutter 依賴"
        Write-Host "  [35] app-gen         - 重新產生 Flutter 程式碼"
        Write-Host "  [36] app-worker      - 編譯 Drift Web Worker"
        Write-Host ""

        Write-Host "=== 🚀 打包部署 (Build) ===" -ForegroundColor DarkCyan
        Write-Host "  [41] build-apk       - 打包 Flutter APK (Prod)"
        Write-Host "  [42] build-appbundle - 打包 Flutter AppBundle (Prod)"
        Write-Host ""

        Write-Host "💡 範例: .\tasks.ps1 31" -ForegroundColor Green
    }
}
