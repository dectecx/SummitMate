package service

import (
	"context"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type HeartbeatService struct {
	repo *repository.HeartbeatRepository
}

func NewHeartbeatService(repo *repository.HeartbeatRepository) *HeartbeatService {
	return &HeartbeatService{repo: repo}
}

func (s *HeartbeatService) HandleHeartbeat(ctx context.Context, userID string, req *HeartbeatRequest) error {
	hb := &model.Heartbeat{
		UserID:   userID,
		UserType: req.UserType,
		View:     req.View,
		Platform: req.Platform,
	}
	return s.repo.Upsert(ctx, hb)
}

type HeartbeatRequest struct {
	UserType string
	View     string
	Platform string
}
