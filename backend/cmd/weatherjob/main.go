package main

import (
	"context"
	"log"

	"summitmate/internal/config"
	"summitmate/internal/database"
	"summitmate/internal/repository"
	"summitmate/internal/service"
)

func main() {
	cfg := config.Load()

	if cfg.CWAApiKey == "" {
		log.Fatal("❌ 未設定 CWA_API_KEY 環境變數")
	}

	ctx := context.Background()

	// 連線資料庫
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("❌ 資料庫連線失敗: %v", err)
	}
	defer pool.Close()

	// 執行 ETL
	weatherRepo := repository.NewWeatherRepository(pool)
	weatherSvc := service.NewWeatherService(weatherRepo, cfg.CWAApiKey)

	log.Println("🌤️  開始執行天氣 ETL...")
	if err := weatherSvc.FetchAndStore(ctx); err != nil {
		log.Fatalf("❌ ETL 執行失敗: %v", err)
	}

	log.Println("🎉 天氣 ETL 完成")
}
