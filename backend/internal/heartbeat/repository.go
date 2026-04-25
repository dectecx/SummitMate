package heartbeat

import (
	"context"
	"fmt"

	"summitmate/internal/database"
)

// HeartbeatRepository 定義心跳資料存取介面。
type HeartbeatRepository interface {
	Upsert(ctx context.Context, hb *Heartbeat) error
}

type heartbeatRepository struct {
	db database.DB
}

func NewHeartbeatRepository(db database.DB) HeartbeatRepository {
	return &heartbeatRepository{db: db}
}

// Upsert 更新或插入心跳資訊
func (r *heartbeatRepository) Upsert(ctx context.Context, hb *Heartbeat) error {
	query := `
		INSERT INTO heartbeats (user_id, user_type, last_seen, view, platform)
		VALUES ($1, $2, NOW(), $3, $4)
		ON CONFLICT (user_id) DO UPDATE
		SET user_type = EXCLUDED.user_type,
			last_seen = NOW(),
			view = EXCLUDED.view,
			platform = EXCLUDED.platform
	`
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, hb.UserID, hb.UserType, hb.View, hb.Platform)
	if err != nil {
		return fmt.Errorf("upsert heartbeat for user %s: %w", hb.UserID, err)
	}
	return nil
}
