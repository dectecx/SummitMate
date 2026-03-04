package main

import (
	"fmt"
	"log"
	"os"

	"summitmate/internal/config"
	"summitmate/internal/database"
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
	cmd := os.Args[1]

	switch cmd {
	case "up":
		if err := database.MigrateUp(cfg.DatabaseURL); err != nil {
			log.Fatalf("❌ migrate up failed: %v", err)
		}
	case "down":
		if err := database.MigrateDown(cfg.DatabaseURL); err != nil {
			log.Fatalf("❌ migrate down failed: %v", err)
		}
	case "version":
		ver, dirty, err := database.MigrateVersion(cfg.DatabaseURL)
		if err != nil {
			log.Fatalf("❌ migrate version failed: %v", err)
		}
		dirtyStr := ""
		if dirty {
			dirtyStr = " (dirty)"
		}
		log.Printf("📌 Current version: %d%s", ver, dirtyStr)
	case "drop":
		fmt.Print("⚠️  This will DROP ALL TABLES. Type 'yes' to confirm: ")
		var confirm string
		fmt.Scanln(&confirm)
		if confirm != "yes" {
			fmt.Println("Cancelled.")
			return
		}
		if err := database.MigrateDrop(cfg.DatabaseURL); err != nil {
			log.Fatalf("❌ migrate drop failed: %v", err)
		}
	default:
		fmt.Printf("Unknown command: %s\n\n", cmd)
		fmt.Print(usage)
		os.Exit(1)
	}
}
