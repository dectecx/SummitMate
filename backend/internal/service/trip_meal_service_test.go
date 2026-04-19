package service

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/model"
	"summitmate/internal/repository"
	"summitmate/internal/trip"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripMealService_ListItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockTripMealRepository)
	mockTripRepo := new(trip.MockTripRepository)
	mockMemberRepo := new(trip.MockTripMemberRepository)
	svc := NewTripMealService(logger, mockRepo, mockTripRepo, mockMemberRepo)

	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("ListByTripID", mock.Anything, tripID).Return([]*model.TripMealItem{
			{ID: "tm1", Name: "Dinner Day 1"},
		}, nil)

		res, err := svc.ListItems(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Len(t, res, 1)
		assert.Equal(t, "Dinner Day 1", res[0].Name)
	})
}

func TestTripMealService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockTripMealRepository)
	mockTripRepo := new(trip.MockTripRepository)
	mockMemberRepo := new(trip.MockTripMemberRepository)
	svc := NewTripMealService(logger, mockRepo, mockTripRepo, mockMemberRepo)

	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"
		item := &model.TripMealItem{Name: "Lunch Day 1"}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(m *model.TripMealItem) bool {
			return m.Name == "Lunch Day 1" && m.TripID == tripID
		})).Return(&model.TripMealItem{ID: "tm1", Name: "Lunch Day 1", TripID: tripID}, nil)

		res, err := svc.CreateItem(context.Background(), tripID, userID, item)

		assert.NoError(t, err)
		assert.Equal(t, "tm1", res.ID)
	})
}

func TestTripMealService_ReplaceAllItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(repository.MockTripMealRepository)
	mockTripRepo := new(trip.MockTripRepository)
	mockMemberRepo := new(trip.MockTripMemberRepository)
	svc := NewTripMealService(logger, mockRepo, mockTripRepo, mockMemberRepo)

	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"
		items := []*model.TripMealItem{
			{ID: "tm1", Name: "Breakfast Day 1"},
		}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("ReplaceAll", mock.Anything, tripID, mock.MatchedBy(func(args []*model.TripMealItem) bool {
			return len(args) == 1 && args[0].Name == "Breakfast Day 1"
		})).Return(nil)

		err := svc.ReplaceAllItems(context.Background(), tripID, userID, items)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}
