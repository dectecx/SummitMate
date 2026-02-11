.PHONY: dev-db dev-api dev-app

## 啟動本地 PostgreSQL
dev-db:
	docker compose up -d db

## 啟動 Go Backend
dev-api:
	cd backend && go run cmd/api/main.go

## 啟動 Flutter App
dev-app:
	cd app && flutter run

## 產生 Swagger 文件
swagger:
	cd backend && swag init -g cmd/api/main.go

## 產生 Flutter API Client (from Swagger)
gen-client:
	openapi-generator-cli generate -i backend/docs/swagger.json -g dart -o app/lib/api
