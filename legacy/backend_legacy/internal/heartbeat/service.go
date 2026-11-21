package heartbeat

import (
	"context"
	"log/slog"
)

// HeartbeatService 定義心跳相關的業務邏輯介面。
type HeartbeatService interface {
	HandleHeartbeat(ctx context.Context, userID string, req *HeartbeatRequest) (*Heartbeat, error)
}

type heartbeatService struct {
	logger *slog.Logger
	repo   HeartbeatRepository
}

func NewHeartbeatService(logger *slog.Logger, repo HeartbeatRepository) HeartbeatService {
	return &heartbeatService{
		logger: logger.With("component", "heartbeat"),
		repo:   repo,
	}
}

func (s *heartbeatService) HandleHeartbeat(ctx context.Context, userID string, req *HeartbeatRequest) (*Heartbeat, error) {
	// 1. 取得現有心跳紀錄（用於同步次數）
	existing, err := s.repo.GetByUserID(ctx, userID)
	if err != nil {
		s.logger.DebugContext(ctx, "未找到現有心跳紀錄，將建立新紀錄", "user_id", userID)
		existing = nil
	}

	// 2. 同步瀏覽統計 (Server-side Win Logic)
	// 如果 Request 次數 < DB 次數，則回傳 DB 次數；反之則更新 DB
	syncedStats := make(map[string]int)
	if existing != nil && existing.ViewStats != nil {
		for k, v := range existing.ViewStats {
			syncedStats[k] = v
		}
	}

	for k, v := range req.ViewStats {
		if v > syncedStats[k] {
			syncedStats[k] = v
		}
	}

	hb := &Heartbeat{
		UserID:    userID,
		UserType:  req.UserType,
		View:      req.View,
		ViewStats: syncedStats,
		Platform:  req.Platform,
	}

	if err := s.repo.Upsert(ctx, hb); err != nil {
		s.logger.ErrorContext(ctx, "更新心跳失敗", "user_id", userID, "error", err)
		return nil, err
	}

	s.logger.DebugContext(ctx, "心跳更新成功", "user_id", userID, "view", req.View)
	return hb, nil
}

type HeartbeatRequest struct {
	UserType  string
	View      string
	ViewStats map[string]int
	Platform  string
}
