package service

import (
	"context"
	"log/slog"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

// LogService 定義日誌上傳相關的業務邏輯介面。
type LogService interface {
	UploadLogs(ctx context.Context, deviceID, deviceName string, logs []model.LogEntry) (int, error)
}

type logService struct {
	logger *slog.Logger
	repo   repository.LogRepository
}

func NewLogService(logger *slog.Logger, repo repository.LogRepository) LogService {
	return &logService{
		logger: logger.With("component", "log_upload"),
		repo:   repo,
	}
}

func (s *logService) UploadLogs(ctx context.Context, deviceID, deviceName string, logs []model.LogEntry) (int, error) {
	count, err := s.repo.BatchCreate(ctx, deviceID, deviceName, logs)
	if err != nil {
		s.logger.ErrorContext(ctx, "上傳裝置日誌失敗", "device_id", deviceID, "device_name", deviceName, "count", len(logs), "error", err)
		return 0, err
	}
	s.logger.InfoContext(ctx, "裝置日誌上傳成功", "device_id", deviceID, "device_name", deviceName, "count", count)
	return count, nil
}
