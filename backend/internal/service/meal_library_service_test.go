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

func TestMealLibraryService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockMealLibraryRepository)
	svc := NewMealLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "u1"
		item := &model.MealLibraryItem{Name: "Energy Bar", Calories: 200}
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(m *model.MealLibraryItem) bool {
			return m.Name == "Energy Bar" && m.UserID == userID
		})).Return(&model.MealLibraryItem{ID: "m1", Name: "Energy Bar", UserID: userID}, nil)

		res, err := svc.CreateItem(context.Background(), userID, item)

		assert.NoError(t, err)
		assert.Equal(t, "m1", res.ID)
		mockRepo.AssertExpectations(t)
	})
}

func TestMealLibraryService_ListItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockMealLibraryRepository)
	svc := NewMealLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "u1"
		mockRepo.On("ListByUserID", mock.Anything, userID, false).Return([]*model.MealLibraryItem{
			{ID: "m1", Name: "Energy Bar"},
		}, nil)

		res, err := svc.ListItems(context.Background(), userID, false)

		assert.NoError(t, err)
		assert.Len(t, res, 1)
		assert.Equal(t, "Energy Bar", res[0].Name)
	})
}
