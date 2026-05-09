package heartbeat

import (
	"context"
	"fmt"

	"summitmate/internal/database"
)

// HeartbeatRepository 定義心跳資料存取介面。
type HeartbeatRepository interface {
	Upsert(ctx context.Context, hb *Heartbeat) error
	GetByUserID(ctx context.Context, userID string) (*Heartbeat, error)
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
		INSERT INTO heartbeats (user_id, user_type, last_seen, view, view_stats, platform)
		VALUES ($1, $2, NOW(), $3, $4, $5)
		ON CONFLICT (user_id) DO UPDATE
		SET user_type = EXCLUDED.user_type,
			last_seen = NOW(),
			view = EXCLUDED.view,
			view_stats = EXCLUDED.view_stats,
			platform = EXCLUDED.platform
	`
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, hb.UserID, hb.UserType, hb.View, hb.ViewStats, hb.Platform)
	if err != nil {
		return fmt.Errorf("upsert heartbeat for user %s: %w", hb.UserID, err)
	}
	return nil
}

func (r *heartbeatRepository) GetByUserID(ctx context.Context, userID string) (*Heartbeat, error) {
	query := `
		SELECT user_id, user_type, last_seen, view, view_stats, platform
		FROM heartbeats
		WHERE user_id = $1
	`
	db := database.GetQuerier(ctx, r.db)
	var hb Heartbeat
	err := db.QueryRow(ctx, query, userID).Scan(
		&hb.UserID, &hb.UserType, &hb.LastSeen, &hb.View, &hb.ViewStats, &hb.Platform,
	)
	if err != nil {
		return nil, fmt.Errorf("get heartbeat for user %s: %w", userID, err)
	}
	return &hb, nil
}
