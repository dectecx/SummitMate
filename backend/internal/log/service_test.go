package log

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func newTestLogEntries() []LogEntry {
	source := "map_screen"
	return []LogEntry{
		{Timestamp: time.Now(), Level: "info", Message: "app started", Source: &source},
		{Timestamp: time.Now(), Level: "error", Message: "gps failed", Source: nil},
	}
}

func TestLogService_UploadLogs(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given repo succeeds, When calling LogService UploadLogs, Then it returns inserted count without error", func(t *testing.T) {
		mockRepo := new(MockLogRepository)
		svc := NewLogService(logger, mockRepo)

		deviceID := "device-1"
		deviceName := "Pixel 8"
		entries := newTestLogEntries()

		mockRepo.On("BatchCreate", mock.Anything, deviceID, deviceName, entries).Return(2, nil).Once()

		count, err := svc.UploadLogs(context.Background(), deviceID, deviceName, entries)

		assert.NoError(t, err)
		assert.Equal(t, 2, count)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given repo returns error, When calling LogService UploadLogs, Then it returns zero count and the error", func(t *testing.T) {
		mockRepo := new(MockLogRepository)
		svc := NewLogService(logger, mockRepo)

		deviceID := "device-2"
		deviceName := "iPhone 15"
		entries := newTestLogEntries()
		repoErr := errors.New("db error")

		mockRepo.On("BatchCreate", mock.Anything, deviceID, deviceName, entries).Return(0, repoErr).Once()

		count, err := svc.UploadLogs(context.Background(), deviceID, deviceName, entries)

		assert.Error(t, err)
		assert.ErrorIs(t, err, repoErr)
		assert.Equal(t, 0, count)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given empty logs, When calling LogService UploadLogs, Then it delegates to repo and returns zero count", func(t *testing.T) {
		mockRepo := new(MockLogRepository)
		svc := NewLogService(logger, mockRepo)

		deviceID := "device-3"
		deviceName := "Galaxy S24"
		entries := []LogEntry{}

		mockRepo.On("BatchCreate", mock.Anything, deviceID, deviceName, entries).Return(0, nil).Once()

		count, err := svc.UploadLogs(context.Background(), deviceID, deviceName, entries)

		assert.NoError(t, err)
		assert.Equal(t, 0, count)
		mockRepo.AssertExpectations(t)
	})
}
