package main

import (
	"fmt"
	"log/slog"
	"os"

	"summitmate/internal/config"
	"summitmate/internal/database"
	appLogger "summitmate/internal/logger"
)

const usage = `SummitMate Migration Tool

Usage:
  go run ./cmd/migrate <command>

Commands:
  up        Apply all pending migrations
  down      Rollback the last migration
  version   Show current migration version
  drop      Drop all tables (DANGER!)
`

func main() {
	if len(os.Args) < 2 {
		fmt.Print(usage)
		os.Exit(1)
	}

	cfg := config.Load()

	logger := appLogger.NewLogger(cfg.Env)
	slog.SetDefault(logger)

	cmd := os.Args[1]

	switch cmd {
	case "up":
		if err := database.MigrateUp(cfg.DatabaseURL); err != nil {
			slog.Error("migrate up failed", "error", err)
			os.Exit(1)
		}
	case "down":
		if err := database.MigrateDown(cfg.DatabaseURL); err != nil {
			slog.Error("migrate down failed", "error", err)
			os.Exit(1)
		}
	case "version":
		ver, dirty, err := database.MigrateVersion(cfg.DatabaseURL)
		if err != nil {
			slog.Error("migrate version failed", "error", err)
			os.Exit(1)
		}
		dirtyStr := ""
		if dirty {
			dirtyStr = " (dirty)"
		}
		slog.Info("current migration version", "version", ver, "dirty", dirtyStr)
	case "drop":
		fmt.Print("⚠️  This will DROP ALL TABLES. Type 'yes' to confirm: ")
		var confirm string
		fmt.Scanln(&confirm)
		if confirm != "yes" {
			fmt.Println("Cancelled.")
			return
		}
		if err := database.MigrateDrop(cfg.DatabaseURL); err != nil {
			slog.Error("migrate drop failed", "error", err)
			os.Exit(1)
		}
	default:
		fmt.Printf("Unknown command: %s\n\n", cmd)
		fmt.Print(usage)
		os.Exit(1)
	}
}
