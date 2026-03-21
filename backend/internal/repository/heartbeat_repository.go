package repository

import (
	"context"
	"summitmate/internal/model"

	"github.com/jackc/pgx/v5/pgxpool"
)

type HeartbeatRepository struct {
	pool *pgxpool.Pool
}

func NewHeartbeatRepository(pool *pgxpool.Pool) *HeartbeatRepository {
	return &HeartbeatRepository{pool: pool}
}

// Upsert 更新或插入心跳資訊
func (r *HeartbeatRepository) Upsert(ctx context.Context, hb *model.Heartbeat) error {
	query := `
		INSERT INTO heartbeats (user_id, user_type, last_seen, view, platform)
		VALUES ($1, $2, NOW(), $3, $4)
		ON CONFLICT (user_id) DO UPDATE
		SET user_type = EXCLUDED.user_type,
			last_seen = NOW(),
			view = EXCLUDED.view,
			platform = EXCLUDED.platform
	`
	_, err := r.pool.Exec(ctx, query, hb.UserID, hb.UserType, hb.View, hb.Platform)
	return err
}
