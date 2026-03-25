package service

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/model"
	"summitmate/internal/repository"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGearLibraryService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockGearLibraryRepository)
	svc := NewGearLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "u1"
		item := &model.GearLibraryItem{Name: "Tent", Weight: 1.5}
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(g *model.GearLibraryItem) bool {
			return g.Name == "Tent" && g.UserID == userID
		})).Return(&model.GearLibraryItem{ID: "g1", Name: "Tent", UserID: userID}, nil)

		res, err := svc.CreateItem(context.Background(), userID, item)

		assert.NoError(t, err)
		assert.Equal(t, "g1", res.ID)
		mockRepo.AssertExpectations(t)
	})
}

func TestGearLibraryService_ListItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockGearLibraryRepository)
	svc := NewGearLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "u1"
		mockRepo.On("ListByUserID", mock.Anything, userID, false).Return([]*model.GearLibraryItem{
			{ID: "g1", Name: "Tent"},
		}, nil)

		res, err := svc.ListItems(context.Background(), userID, false)

		assert.NoError(t, err)
		assert.Len(t, res, 1)
		assert.Equal(t, "Tent", res[0].Name)
	})
}
