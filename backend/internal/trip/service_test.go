package trip_test

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	"summitmate/internal/trip"
	tripmocks "summitmate/internal/trip/mocks"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripService_CreateTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given valid setup, When calling TripService CreateTrip, Then it returns success without error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)

		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		userID := "user-1"
		req := &trip.TripCreateRequest{
			Name:      "Test Trip",
			StartDate: time.Now(),
		}

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Commit", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.AnythingOfType("*trip.Trip")).Return(&trip.Trip{
			ID:     "trip-1",
			Name:   req.Name,
			UserID: userID,
		}, nil)

		mockMemberRepo.On("AddMember", mock.Anything, "trip-1", userID).Return(nil)
		mockMealDayRepo.On("Create", mock.Anything, mock.Anything).Return(&trip.MealPlanDay{ID: "day-1"}, nil)

		tTrip, err := svc.CreateTrip(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, tTrip)
		assert.Equal(t, "trip-1", tTrip.ID)
		mockTripRepo.AssertExpectations(t)
		mockMemberRepo.AssertExpectations(t)
	})

	t.Run("Given database error, When calling TripService CreateTrip, Then it returns corresponding database error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)

		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Rollback", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.Anything).Return(nil, errors.New("db error"))

		tTrip, err := svc.CreateTrip(context.Background(), "u1", &trip.TripCreateRequest{Name: "Fail"})

		assert.Error(t, err)
		assert.Nil(t, tTrip)
	})
}

func TestTripService_GetTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given Success AsCreator, When calling TripService GetTrip, Then it behaves as expected", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-creator"
		mockTrip := &trip.Trip{ID: tripID, UserID: userID}
		mockMealDayRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.MealPlanDay{}, nil)

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		tTrip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, tTrip)
	})

	t.Run("Given resource is not found, When calling TripService GetTrip, Then it returns not found error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockTripRepo.On("GetByID", mock.Anything, "none").Return(nil, trip.ErrNotFound)

		tTrip, err := svc.GetTrip(context.Background(), "none", "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrTripNotFound, err)
		assert.Nil(t, tTrip)
	})
}

func TestTripService_AddMember(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given valid setup, When calling TripService AddMember, Then it returns success without error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockUserRepo := new(authmocks.MockUserRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, mockUserRepo)

		tripID := "trip-1"
		requesterID := "creator"
		targetUserID := "user-new"
		targetEmail := "new@example.com"

		mockTrip := &trip.Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &auth.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, targetUserID).Return(false, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.TripMember{
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

	t.Run("Given Success Unlinked, When calling TripService DeleteMealPlanDay, Then it behaves as expected", func(t *testing.T) {
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, nil, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"

		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
			ID:     dayID,
			TripID: tripID,
			Name:   "Unlinked Day",
		}, nil)
		mockMealDayRepo.On("Delete", mock.Anything, dayID, tripID).Return(nil)

		err := svc.DeleteMealPlanDay(context.Background(), tripID, dayID, userID)

		assert.NoError(t, err)
		mockMealDayRepo.AssertExpectations(t)
	})

	t.Run("Given Fail Linked, When calling TripService DeleteMealPlanDay, Then it behaves as expected", func(t *testing.T) {
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, nil, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"
		linked := "D1"

		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
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
