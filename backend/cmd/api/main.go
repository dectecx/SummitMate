package main

import (
	"log/slog"
	"os"

	"summitmate/internal/app"
	"summitmate/internal/config"
	appLogger "summitmate/internal/logger"
)

func main() {
	// 1. Load Configuration (only returns *Config)
	cfg := config.Load()

	// 2. Initialize Logger (takes env string)
	logger := appLogger.NewLogger(cfg.Env)
	slog.SetDefault(logger)

	// 3. Initialize and Run Application
	application, err := app.NewApp(cfg, logger)
	if err != nil {
		slog.Error("Failed to initialize application", "error", err)
		os.Exit(1)
	}

	if err := application.Run(); err != nil {
		slog.Error("Application terminated unexpectedly", "error", err)
		os.Exit(1)
	}
}
