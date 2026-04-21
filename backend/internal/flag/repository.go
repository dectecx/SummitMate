package flag

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	GetByKey(ctx context.Context, key string) (*Flag, error)
	GetAll(ctx context.Context) ([]Flag, error)
	Update(ctx context.Context, key string, value bool) error
}

type repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) GetByKey(ctx context.Context, key string) (*Flag, error) {
	var f Flag
	err := r.pool.QueryRow(ctx, "SELECT key, value, description, updated_at FROM system_flags WHERE key = $1", key).
		Scan(&f.Key, &f.Value, &f.Description, &f.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &f, nil
}

func (r *repository) GetAll(ctx context.Context) ([]Flag, error) {
	rows, err := r.pool.Query(ctx, "SELECT key, value, description, updated_at FROM system_flags")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var flags []Flag
	for rows.Next() {
		var f Flag
		if err := rows.Scan(&f.Key, &f.Value, &f.Description, &f.UpdatedAt); err != nil {
			return nil, err
		}
		flags = append(flags, f)
	}
	return flags, nil
}

func (r *repository) Update(ctx context.Context, key string, value bool) error {
	_, err := r.pool.Exec(ctx, "UPDATE system_flags SET value = $1, updated_at = CURRENT_TIMESTAMP WHERE key = $2", value, key)
	return err
}
