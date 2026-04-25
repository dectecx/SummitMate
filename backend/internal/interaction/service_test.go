package interaction

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/apperror"
	"summitmate/internal/trip"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestMessageService_AddTripMessage(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockMessageRepository)
	mockTripRepo := new(trip.MockTripRepository)
	mockMemberRepo := new(trip.MockTripMemberRepository)
	svc := NewMessageService(logger, mockRepo, mockTripRepo, mockMemberRepo)

	t.Run("Success", func(t *testing.T) {
		tripID := "trip-1"
		userID := "user-1"
		msg := &TripMessage{Content: "Hello"}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil).Once()
		mockRepo.On("CreateMessage", mock.Anything, msg).Return(nil).Once()

		result, err := svc.AddTripMessage(context.Background(), tripID, userID, msg)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, userID, result.UserID)
		mockRepo.AssertExpectations(t)
	})

	t.Run("AccessDenied", func(t *testing.T) {
		tripID := "trip-1"
		userID := "user-other"
		msg := &TripMessage{Content: "Hello"}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: "creator"}, nil).Once()
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.TripMember{}, nil).Once()

		result, err := svc.AddTripMessage(context.Background(), tripID, userID, msg)

		assert.ErrorIs(t, err, apperror.ErrAccessDenied)
		assert.Nil(t, result)
	})
}

func TestPollService_VoteOption(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockPollRepository)
	mockTripRepo := new(trip.MockTripRepository)
	mockMemberRepo := new(trip.MockTripMemberRepository)
	svc := NewPollService(logger, mockRepo, mockTripRepo, mockMemberRepo)

	t.Run("Success", func(t *testing.T) {
		tripID := "trip-1"
		pollID := "poll-1"
		optionID := "opt-1"
		userID := "user-1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil).Once()
		mockRepo.On("GetPollByID", mock.Anything, pollID).Return(&Poll{ID: pollID, TripID: tripID, Status: "open", AllowMultipleVotes: false}, nil).Once()
		mockRepo.On("VoteOption", mock.Anything, pollID, optionID, userID, false).Return(nil).Once()
		mockRepo.On("GetPollByID", mock.Anything, pollID).Return(&Poll{ID: pollID}, nil).Once()

		result, err := svc.VoteOption(context.Background(), tripID, pollID, optionID, userID)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("PollClosed", func(t *testing.T) {
		tripID := "trip-1"
		pollID := "poll-1"
		userID := "user-1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: userID}, nil).Once()
		mockRepo.On("GetPollByID", mock.Anything, pollID).Return(&Poll{ID: pollID, TripID: tripID, Status: "closed"}, nil).Once()

		result, err := svc.VoteOption(context.Background(), tripID, pollID, "opt-1", userID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "投票活動已結束")
		assert.Nil(t, result)
	})
}
