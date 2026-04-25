package library

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGearLibraryService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGearLibraryRepository)
	svc := NewGearLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "user-1"
		req := &GearLibraryItem{Name: "Tent"}
		expected := &GearLibraryItem{ID: "item-1", Name: "Tent", UserID: userID}

		mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*library.GearLibraryItem")).Return(expected, nil).Once()

		result, err := svc.CreateItem(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.Equal(t, expected, result)
		mockRepo.AssertExpectations(t)
	})
}

func TestMealLibraryService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockMealLibraryRepository)
	svc := NewMealLibraryService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		userID := "user-1"
		req := &MealLibraryItem{Name: "Pasta"}
		expected := &MealLibraryItem{ID: "item-1", Name: "Pasta", UserID: userID}

		mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*library.MealLibraryItem")).Return(expected, nil).Once()

		result, err := svc.CreateItem(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.Equal(t, expected, result)
		mockRepo.AssertExpectations(t)
	})
}
