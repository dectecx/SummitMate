// Command migrate applies migrations/000001_init_schema.up.sql to a database.
// Dev-only: during initial development there is a single schema file, so this
// is meant for an empty database (drop and recreate it to reset).
package main

import (
	"context"
	"fmt"
	"os"

	"summitmate/internal/platform/config"
	"summitmate/internal/platform/database"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run() error {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		cfg, err := config.Load()
		if err != nil {
			return err
		}
		url = cfg.DatabaseURL
	}
	ctx := context.Background()
	pool, err := database.Open(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()
	return database.ApplySchema(ctx, pool, "migrations/000001_init_schema.up.sql")
}
