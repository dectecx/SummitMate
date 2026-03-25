package service

import (
	"context"
	"log/slog"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

// HeartbeatService 定義心跳相關的業務邏輯介面。
type HeartbeatService interface {
	HandleHeartbeat(ctx context.Context, userID string, req *HeartbeatRequest) error
}

type heartbeatService struct {
	logger *slog.Logger
	repo   repository.HeartbeatRepository
}

func NewHeartbeatService(logger *slog.Logger, repo repository.HeartbeatRepository) HeartbeatService {
	return &heartbeatService{
		logger: logger.With("component", "heartbeat"),
		repo:   repo,
	}
}

func (s *heartbeatService) HandleHeartbeat(ctx context.Context, userID string, req *HeartbeatRequest) error {
	hb := &model.Heartbeat{
		UserID:   userID,
		UserType: req.UserType,
		View:     req.View,
		Platform: req.Platform,
	}
	if err := s.repo.Upsert(ctx, hb); err != nil {
		s.logger.ErrorContext(ctx, "更新心跳失敗", "user_id", userID, "view", req.View, "platform", req.Platform, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "心跳更新成功", "user_id", userID, "view", req.View, "platform", req.Platform)
	return nil
}

type HeartbeatRequest struct {
	UserType string
	View     string
	Platform string
}
