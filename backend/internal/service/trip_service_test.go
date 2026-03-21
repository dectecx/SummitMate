package service

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripService_CreateTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		mockMemberRepo := new(repository.MockTripMemberRepository)
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, nil)

		userID := "user-1"
		req := &TripCreateRequest{
			Name:      "Test Trip",
			StartDate: time.Now(),
		}

		createdTrip := &model.User{ID: "trip-1"} // Wait, model.Trip not model.User
		_ = createdTrip                          // fix below

		mockTripRepo.On("Create", mock.Anything, mock.AnythingOfType("*model.Trip")).Return(&model.Trip{
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
		mockTripRepo := new(repository.MockTripRepository)
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
		mockTripRepo := new(repository.MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "user-creator"
		mockTrip := &model.Trip{ID: tripID, UserID: userID}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		trip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, trip)
	})

	t.Run("Success_AsMember", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		mockMemberRepo := new(repository.MockTripMemberRepository)
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, nil)

		tripID := "trip-1"
		userID := "user-member"
		creatorID := "user-creator"
		mockTrip := &model.Trip{ID: tripID, UserID: creatorID}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*model.TripMember{
			{UserID: userID},
		}, nil)

		trip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, trip)
	})

	t.Run("AccessDenied", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		mockMemberRepo := new(repository.MockTripMemberRepository)
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, nil)

		tripID := "trip-1"
		userID := "stranger"
		mockTrip := &model.Trip{ID: tripID, UserID: "creator"}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*model.TripMember{}, nil)

		trip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrAccessDenied, err)
		assert.Nil(t, trip)
	})

	t.Run("NotFound", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		mockTripRepo.On("GetByID", mock.Anything, "none").Return(nil, repository.ErrNotFound)

		trip, err := svc.GetTrip(context.Background(), "none", "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrTripNotFound, err)
		assert.Nil(t, trip)
	})
}

func TestTripService_UpdateTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "creator"
		existing := &model.Trip{ID: tripID, UserID: userID, Name: "Old Name"}
		newName := "New Name"
		req := &TripUpdateRequest{Name: &newName}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(existing, nil)
		mockTripRepo.On("Update", mock.Anything, mock.MatchedBy(func(u *model.Trip) bool {
			return u.Name == newName
		})).Return(&model.Trip{ID: tripID, Name: newName}, nil)

		trip, err := svc.UpdateTrip(context.Background(), tripID, userID, req)

		assert.NoError(t, err)
		assert.Equal(t, newName, trip.Name)
	})
}

func TestTripService_DeleteTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "creator"
		mockTrip := &model.Trip{ID: tripID, UserID: userID}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockTripRepo.On("DeleteByID", mock.Anything, tripID).Return(nil)

		err := svc.DeleteTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
	})

	t.Run("NoPermission", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		svc := NewTripService(logger, mockTripRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "not-creator"
		mockTrip := &model.Trip{ID: tripID, UserID: "other"}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		err := svc.DeleteTrip(context.Background(), tripID, userID)

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrAccessDenied, err)
	})
}

func TestTripService_AddMember(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Success", func(t *testing.T) {
		mockTripRepo := new(repository.MockTripRepository)
		mockMemberRepo := new(repository.MockTripMemberRepository)
		mockUserRepo := new(repository.MockUserRepository)
		svc := NewTripService(logger, mockTripRepo, mockMemberRepo, nil, mockUserRepo)

		tripID := "trip-1"
		requesterID := "creator"
		targetEmail := "new@example.com"
		targetUserID := "user-new"

		mockTrip := &model.Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &model.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockUserRepo.On("GetByEmail", mock.Anything, targetEmail).Return(mockTargetUser, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*model.TripMember{
			{UserID: targetUserID, UserDisplayName: mockTargetUser.DisplayName, UserEmail: mockTargetUser.Email},
		}, nil)

		member, err := svc.AddMember(context.Background(), tripID, requesterID, targetEmail)

		assert.NoError(t, err)
		assert.NotNil(t, member)
		assert.Equal(t, targetUserID, member.UserID)
	})
}
