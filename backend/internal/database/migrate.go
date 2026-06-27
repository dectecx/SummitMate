package database

import (
	"database/sql"
	"fmt"
	"log/slog"

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
		db.Close()
		return nil, fmt.Errorf("create migrate: %w", err)
	}
	return m, nil
}

// closeMigrate closes the migrate instance (and its underlying DB connection),
// logging any error without overriding the operation's own result.
func closeMigrate(m *migrate.Migrate) {
	if srcErr, dbErr := m.Close(); srcErr != nil || dbErr != nil {
		slog.Warn("Failed to close migrate instance", "source_err", srcErr, "db_err", dbErr)
	}
}

// MigrateUp applies all pending migrations.
func MigrateUp(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}
	defer closeMigrate(m)

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("up: %w", err)
	}

	slog.Info("Migrations applied successfully")
	return nil
}

// MigrateDown rolls back the last migration.
func MigrateDown(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}
	defer closeMigrate(m)

	if err := m.Steps(-1); err != nil {
		return fmt.Errorf("down: %w", err)
	}

	slog.Info("Rolled back 1 migration")
	return nil
}

// MigrateVersion returns the current migration version.
func MigrateVersion(databaseURL string) (uint, bool, error) {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return 0, false, err
	}
	defer closeMigrate(m)

	return m.Version()
}

// MigrateDrop drops all tables by running all down migrations.
func MigrateDrop(databaseURL string) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}
	defer closeMigrate(m)

	if err := m.Down(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("drop: %w", err)
	}

	slog.Info("All tables dropped")
	return nil
}

// MigrateForce forces the migration version in the database.
func MigrateForce(databaseURL string, version int) error {
	m, err := newMigrate(databaseURL)
	if err != nil {
		return err
	}
	defer closeMigrate(m)

	if err := m.Force(version); err != nil {
		return fmt.Errorf("force: %w", err)
	}

	slog.Info("Migration version forced", "version", version)
	return nil
}
