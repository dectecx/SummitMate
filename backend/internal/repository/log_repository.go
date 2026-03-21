package repository

import (
	"context"
	"fmt"

	"summitmate/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type LogRepository struct {
	pool *pgxpool.Pool
}

func NewLogRepository(pool *pgxpool.Pool) *LogRepository {
	return &LogRepository{pool: pool}
}

// BatchCreate 批次建立日誌
func (r *LogRepository) BatchCreate(ctx context.Context, deviceID, deviceName string, entries []model.LogEntry) (int, error) {
	if len(entries) == 0 {
		return 0, nil
	}

	// 使用 CopyFrom 進行極速批次插入
	rows := make([][]any, len(entries))
	for i, entry := range entries {
		source := ""
		if entry.Source != nil {
			source = *entry.Source
		}
		rows[i] = []any{
			deviceID,
			deviceName,
			entry.Timestamp,
			entry.Level,
			source,
			entry.Message,
		}
	}

	count, err := r.pool.CopyFrom(
		ctx,
		pgx.Identifier{"logs"},
		[]string{"device_id", "device_name", "timestamp", "level", "source", "message"},
		pgx.CopyFromRows(rows),
	)

	if err != nil {
		return 0, fmt.Errorf("failed to batch insert logs: %w", err)
	}

	return int(count), nil
}
