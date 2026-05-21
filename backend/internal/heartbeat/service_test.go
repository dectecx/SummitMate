package heartbeat

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestHeartbeatService_HandleHeartbeat(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("NewRecordSuccess", func(t *testing.T) {
		mockRepo := new(MockHeartbeatRepository)
		svc := NewHeartbeatService(logger, mockRepo)

		userID := "user-new"
		req := &HeartbeatRequest{
			UserType: "MEMBER",
			View:     "/trips/1",
			Platform: "iOS",
			ViewStats: map[string]int{
				"trip-list": 3,
				"trip-page": 1,
			},
		}

		// DB 找不到該用戶心跳紀錄，回傳錯誤或 nil
		mockRepo.On("GetByUserID", mock.Anything, userID).Return((*Heartbeat)(nil), errors.New("not found")).Once()

		// 預期 Upsert 呼叫，並檢查傳入的 Heartbeat 結構
		mockRepo.On("Upsert", mock.Anything, mock.MatchedBy(func(hb *Heartbeat) bool {
			return hb.UserID == userID &&
				hb.UserType == "MEMBER" &&
				hb.View == "/trips/1" &&
				hb.Platform == "iOS" &&
				hb.ViewStats["trip-list"] == 3 &&
				hb.ViewStats["trip-page"] == 1
		})).Return(nil).Once()

		result, err := svc.HandleHeartbeat(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, userID, result.UserID)
		assert.Equal(t, "MEMBER", result.UserType)
		assert.Equal(t, 3, result.ViewStats["trip-list"])
		mockRepo.AssertExpectations(t)
	})

	t.Run("ExistingRecordServerSideWin", func(t *testing.T) {
		mockRepo := new(MockHeartbeatRepository)
		svc := NewHeartbeatService(logger, mockRepo)

		userID := "user-existing"
		req := &HeartbeatRequest{
			UserType: "MEMBER",
			View:     "/trips/2",
			Platform: "Android",
			ViewStats: map[string]int{
				"trip-list": 2, // 請求的次數小於 DB 的次數 (應保持 DB)
				"trip-page": 5, // 請求的次數大於 DB 的次數 (應更新)
				"profile":   1, // 請求新新增的次數 (應更新)
			},
		}

		existing := &Heartbeat{
			UserID:   userID,
			UserType: "MEMBER",
			View:     "/trips/1",
			Platform: "Android",
			ViewStats: map[string]int{
				"trip-list": 4, // DB 中有更進步的統計
				"trip-page": 2, // DB 較舊
			},
		}

		mockRepo.On("GetByUserID", mock.Anything, userID).Return(existing, nil).Once()

		// 預期合併後的 ViewStats:
		// trip-list: max(2, 4) = 4
		// trip-page: max(5, 2) = 5
		// profile: max(1, 0) = 1
		mockRepo.On("Upsert", mock.Anything, mock.MatchedBy(func(hb *Heartbeat) bool {
			return hb.UserID == userID &&
				hb.ViewStats["trip-list"] == 4 &&
				hb.ViewStats["trip-page"] == 5 &&
				hb.ViewStats["profile"] == 1
		})).Return(nil).Once()

		result, err := svc.HandleHeartbeat(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, 4, result.ViewStats["trip-list"])
		assert.Equal(t, 5, result.ViewStats["trip-page"])
		assert.Equal(t, 1, result.ViewStats["profile"])
		mockRepo.AssertExpectations(t)
	})

	t.Run("UpsertError", func(t *testing.T) {
		mockRepo := new(MockHeartbeatRepository)
		svc := NewHeartbeatService(logger, mockRepo)

		userID := "user-err"
		req := &HeartbeatRequest{
			UserType: "MEMBER",
			View:     "/home",
		}

		mockRepo.On("GetByUserID", mock.Anything, userID).Return((*Heartbeat)(nil), errors.New("not found")).Once()
		mockRepo.On("Upsert", mock.Anything, mock.Anything).Return(errors.New("db write failed")).Once()

		result, err := svc.HandleHeartbeat(context.Background(), userID, req)

		assert.Error(t, err)
		assert.Nil(t, result)
		mockRepo.AssertExpectations(t)
	})
}
