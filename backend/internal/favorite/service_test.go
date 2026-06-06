package favorite

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockBeginner struct {
	mock.Mock
}

func (m *MockBeginner) Begin(ctx context.Context) (pgx.Tx, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(pgx.Tx), args.Error(1)
}

func TestFavoriteService_AddFavorite(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	mockDB := new(MockBeginner)
	svc := NewFavoriteService(logger, mockDB, mockRepo)

	t.Run("Given valid setup, When calling FavoriteService AddFavorite, Then it returns success without error", func(t *testing.T) {
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
	mockDB := new(MockBeginner)
	svc := NewFavoriteService(logger, mockDB, mockRepo)

	t.Run("Given valid setup, When calling FavoriteService RemoveFavorite, Then it returns success without error", func(t *testing.T) {
		userID := "user-1"
		targetID := "target-1"

		mockRepo.On("DeleteByTargetAndUser", mock.Anything, targetID, userID).Return(nil).Once()

		err := svc.RemoveFavorite(context.Background(), targetID, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}
