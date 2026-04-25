package favorite

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestFavoriteService_AddFavorite(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	svc := NewFavoriteService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "user-1"
		targetID := "target-1"
		favType := "trip"

		mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*favorite.Favorite")).Return(nil).Once()

		result, err := svc.AddFavorite(context.Background(), userID, targetID, favType)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, userID, result.UserID)
		assert.Equal(t, targetID, result.TargetID)
		mockRepo.AssertExpectations(t)
	})
}

func TestFavoriteService_RemoveFavorite(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	svc := NewFavoriteService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "user-1"
		targetID := "target-1"

		mockRepo.On("DeleteByTargetAndUser", mock.Anything, targetID, userID).Return(nil).Once()

		err := svc.RemoveFavorite(context.Background(), targetID, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}
