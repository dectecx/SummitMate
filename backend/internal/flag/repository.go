package flag

import (
	"context"
	"fmt"

	"summitmate/internal/database"
)

type Repository interface {
	GetByKey(ctx context.Context, key string) (*Flag, error)
	GetAll(ctx context.Context) ([]Flag, error)
	Update(ctx context.Context, key string, value bool) error
}

type repository struct {
	db database.DB
}

func NewRepository(db database.DB) Repository {
	return &repository{db: db}
}

func (r *repository) GetByKey(ctx context.Context, key string) (*Flag, error) {
	var f Flag
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, "SELECT key, value, description, updated_at FROM system_flags WHERE key = $1", key).
		Scan(&f.Key, &f.Value, &f.Description, &f.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("get system flag %s: %w", key, err)
	}
	return &f, nil
}

func (r *repository) GetAll(ctx context.Context) ([]Flag, error) {
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, "SELECT key, value, description, updated_at FROM system_flags")
	if err != nil {
		return nil, fmt.Errorf("query all system flags: %w", err)
	}
	defer rows.Close()

	var flags []Flag
	for rows.Next() {
		var f Flag
		if err := rows.Scan(&f.Key, &f.Value, &f.Description, &f.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan system flag row: %w", err)
		}
		flags = append(flags, f)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate system flag rows: %w", err)
	}
	return flags, nil
}

func (r *repository) Update(ctx context.Context, key string, value bool) error {
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, "UPDATE system_flags SET value = $1, updated_at = CURRENT_TIMESTAMP WHERE key = $2", value, key)
	if err != nil {
		return fmt.Errorf("update system flag %s: %w", key, err)
	}
	return nil
}
