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
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, nil)

		userID := "user-1"
		req := &TripCreateRequest{
			Name:      "Test Trip",
			StartDate: time.Now(),
		}

		mockTripRepo.On("Create", mock.Anything, mock.AnythingOfType("*trip.Trip")).Return(&Trip{
			ID:     "trip-1",
			Name:   req.Name,
			UserID: userID,
		}, nil)

		mockMemberRepo.On("AddMember", mock.Anything, "trip-1", userID).Return(nil)

		trip, err := svc.CreateTrip(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, trip)
		assert.Equal(t, "trip-1", trip.ID)
		mockTripRepo.AssertExpectations(t)
		mockMemberRepo.AssertExpectations(t)
	})

	t.Run("RepoError", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

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
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "user-creator"
		mockTrip := &Trip{ID: tripID, UserID: userID}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		trip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, trip)
	})

	t.Run("NotFound", func(t *testing.T) {
		mockTripRepo := new(MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

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
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, mockUserRepo)

		tripID := "trip-1"
		requesterID := "creator"
		targetEmail := "new@example.com"
		targetUserID := "user-new"

		mockTrip := &Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &auth.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockUserRepo.On("GetByEmail", mock.Anything, targetEmail).Return(mockTargetUser, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*TripMember{
			{UserID: targetUserID, UserDisplayName: mockTargetUser.DisplayName, UserEmail: mockTargetUser.Email},
		}, nil)

		member, err := svc.AddMember(context.Background(), tripID, requesterID, targetEmail)

		assert.NoError(t, err)
		assert.NotNil(t, member)
		assert.Equal(t, targetUserID, member.UserID)
	})
}
