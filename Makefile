.PHONY: dev-db dev-api dev-app api-gen app-gen app-get

## 啟動本地 PostgreSQL
dev-db:
	docker compose up -d db

## 啟動 Go Backend
dev-api:
	cd backend && go run cmd/api/main.go

## 啟動 Flutter App (Web)
dev-app:
	cd app && flutter run -d chrome

## 重新產生後端 API 程式碼 (from openapi.yaml)
api-gen:
	cd backend && go generate ./...

## 安裝 Flutter 依賴
app-get:
	cd app && flutter pub get

## 重新產生 Flutter 程式碼 (Freezed, Retrofit, Drift, json_serializable, injectable)
app-gen:
	cd app && dart run build_runner build --delete-conflicting-outputs

## 編譯 Drift Web Worker (Web 平台需要)
app-worker:
	cd app && dart compile js web/drift_worker.dart -o web/drift_worker.js
