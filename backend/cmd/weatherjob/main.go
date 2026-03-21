package main

import (
	"context"
	"log/slog"
	"os"

	"summitmate/internal/config"
	"summitmate/internal/database"
	appLogger "summitmate/internal/logger"
	"summitmate/internal/repository"
	"summitmate/internal/service"
)

func main() {
	cfg := config.Load()

	logger := appLogger.NewLogger(cfg.Env)
	slog.SetDefault(logger)

	if cfg.CWAApiKey == "" {
		slog.Error("未設定 CWA_API_KEY 環境變數")
		os.Exit(1)
	}

	ctx := context.Background()

	// 連線資料庫
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("資料庫連線失敗", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	// 執行 ETL
	weatherRepo := repository.NewWeatherRepository(pool)
	weatherSvc := service.NewWeatherService(logger, weatherRepo, cfg.CWAApiKey, nil)

	slog.Info("開始執行天氣 ETL")
	if err := weatherSvc.FetchAndStore(ctx); err != nil {
		slog.Error("ETL 執行失敗", "error", err)
		os.Exit(1)
	}

	slog.Info("天氣 ETL 完成")
}
