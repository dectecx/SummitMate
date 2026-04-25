package log

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

// LogRepository 定義日誌資料存取介面。
type LogRepository interface {
	BatchCreate(ctx context.Context, deviceID, deviceName string, entries []LogEntry) (int, error)
}

type logRepository struct {
	db database.DB
}

func NewLogRepository(db database.DB) LogRepository {
	return &logRepository{db: db}
}

// BatchCreate 批次建立日誌
func (r *logRepository) BatchCreate(ctx context.Context, deviceID, deviceName string, entries []LogEntry) (int, error) {
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

	db := database.GetQuerier(ctx, r.db)
	count, err := db.CopyFrom(
		ctx,
		pgx.Identifier{"logs"},
		[]string{"device_id", "device_name", "timestamp", "level", "source", "message"},
		pgx.CopyFromRows(rows),
	)

	if err != nil {
		return 0, fmt.Errorf("batch insert logs for device %s: %w", deviceID, err)
	}

	return int(count), nil
}
