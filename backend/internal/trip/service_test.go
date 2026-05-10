package trip

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripService_CreateTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		mockMemberRepo := new(MockTripMemberRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)

		svc := NewTripService(logger, mockBeginner, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		userID := "user-1"
		req := &TripCreateRequest{
			Name:      "Test Trip",
			StartDate: time.Now(),
		}

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Commit", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.AnythingOfType("*trip.Trip")).Return(&Trip{
			ID:     "trip-1",
			Name:   req.Name,
			UserID: userID,
		}, nil)

		mockMemberRepo.On("AddMember", mock.Anything, "trip-1", userID).Return(nil)
		mockMealDayRepo.On("Create", mock.Anything, mock.Anything).Return(&MealPlanDay{ID: "day-1"}, nil)

		trip, err := svc.CreateTrip(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, trip)
		assert.Equal(t, "trip-1", trip.ID)
		mockTripRepo.AssertExpectations(t)
		mockMemberRepo.AssertExpectations(t)
	})

	t.Run("RepoError", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)

		svc := NewTripService(logger, mockBeginner, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Rollback", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.Anything).Return(nil, errors.New("db error"))

		trip, err := svc.CreateTrip(context.Background(), "u1", &TripCreateRequest{Name: "Fail"})

		assert.Error(t, err)
		assert.Nil(t, trip)
	})
}

func TestTripService_GetTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success_AsCreator", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)
		svc := NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-creator"
		mockTrip := &Trip{ID: tripID, UserID: userID}
		mockMealDayRepo.On("ListByTripID", mock.Anything, tripID).Return([]*MealPlanDay{}, nil)

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		trip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, trip)
	})

	t.Run("NotFound", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)
		svc := NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockTripRepo.On("GetByID", mock.Anything, "none").Return(nil, ErrNotFound)

		trip, err := svc.GetTrip(context.Background(), "none", "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrTripNotFound, err)
		assert.Nil(t, trip)
	})
}

func TestTripService_AddMember(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		mockMemberRepo := new(MockTripMemberRepository)
		mockUserRepo := new(auth.MockUserRepository)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)
		svc := NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, mockUserRepo)

		tripID := "trip-1"
		requesterID := "creator"
		targetEmail := "new@example.com"
		targetUserID := "user-new"

		mockTrip := &Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &auth.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, targetUserID).Return(false, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*TripMember{
			{UserID: targetUserID, UserDisplayName: mockTargetUser.DisplayName, UserEmail: mockTargetUser.Email},
		}, nil)

		member, err := svc.AddMember(context.Background(), tripID, requesterID, targetUserID)

		assert.NoError(t, err)
		assert.NotNil(t, member)
		assert.Equal(t, targetUserID, member.UserID)
	})
}

func TestTripService_DeleteMealPlanDay(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success_Unlinked", func(t *testing.T) {
		mockMemberRepo := new(MockTripMemberRepository)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)
		svc := NewTripService(logger, nil, nil, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"

		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&MealPlanDay{
			ID:     dayID,
			TripID: tripID,
			Name:   "Unlinked Day",
		}, nil)
		mockMealDayRepo.On("Delete", mock.Anything, dayID, tripID).Return(nil)

		err := svc.DeleteMealPlanDay(context.Background(), tripID, dayID, userID)

		assert.NoError(t, err)
		mockMealDayRepo.AssertExpectations(t)
	})

	t.Run("Fail_Linked", func(t *testing.T) {
		mockMemberRepo := new(MockTripMemberRepository)
		mockMealDayRepo := new(MockTripMealPlanDayRepository)
		svc := NewTripService(logger, nil, nil, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"
		linked := "D1"

		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&MealPlanDay{
			ID:                 dayID,
			TripID:             tripID,
			Name:               "D1",
			LinkedItineraryDay: &linked,
		}, nil)

		err := svc.DeleteMealPlanDay(context.Background(), tripID, dayID, userID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "已綁定行程")
	})
}
