package database

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func newMigrate(databaseURL string) (*migrate.Migrate, error) {
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("create driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"summitmate",
		driver,
	)
	if err != nil {
		return nil, fmt.Errorf("create migrate: %w", err)
	}
	return m, nil
}

// MigrateUp applies all pending migrations.
func MigrateUp(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("up: %w", err)
	}

	log.Println("✅ Migrations applied successfully")
	return nil
}

// MigrateDown rolls back the last migration.
func MigrateDown(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}

	if err := m.Steps(-1); err != nil {
		return fmt.Errorf("down: %w", err)
	}

	log.Println("✅ Rolled back 1 migration")
	return nil
}

// MigrateVersion returns the current migration version.
func MigrateVersion(databaseURL string) (uint, bool, error) {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return 0, false, err
	}
	return m.Version()
}

// MigrateDrop drops all tables by running all down migrations.
func MigrateDrop(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}

	if err := m.Down(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("drop: %w", err)
	}

	log.Println("✅ All tables dropped")
	return nil
}
