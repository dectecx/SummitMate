package service

import (
	"context"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type LogService struct {
	repo *repository.LogRepository
}

func NewLogService(repo *repository.LogRepository) *LogService {
	return &LogService{repo: repo}
}

func (s *LogService) UploadLogs(ctx context.Context, deviceID, deviceName string, logs []model.LogEntry) (int, error) {
	return s.repo.BatchCreate(ctx, deviceID, deviceName, logs)
}
