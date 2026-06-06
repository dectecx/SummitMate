package groupevent

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	tripmocks "summitmate/internal/trip/mocks"

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

func TestGroupEventService_CreateEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	mockTrip := new(tripmocks.MockTripService)
	mockAuth := new(authmocks.MockAuthService)
	mockDB := new(MockBeginner)
	svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)

	t.Run("Given valid setup, When calling GroupEventService CreateEvent, Then it returns success without error", func(t *testing.T) {
		event := &GroupEvent{
			Title:      "Hiking Trip",
			HostID:     "user-1",
			HostName:   "Host User",
			HostAvatar: "avatar-1",
			CreatedBy:  "user-1",
		}
		mockRepo.On("CreateEvent", mock.Anything, event).Return(nil).Once()

		err := svc.CreateEvent(context.Background(), event)

		assert.NoError(t, err)
		assert.Equal(t, "open", event.Status)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given EmptyTitle, When calling GroupEventService CreateEvent, Then it behaves as expected", func(t *testing.T) {
		event := &GroupEvent{Title: ""}
		err := svc.CreateEvent(context.Background(), event)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "活動標題為必填")
	})
}

func TestGroupEventService_UpdateEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	mockTrip := new(tripmocks.MockTripService)
	mockAuth := new(authmocks.MockAuthService)
	mockDB := new(MockBeginner)
	svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)

	t.Run("Given valid setup, When calling GroupEventService UpdateEvent, Then it returns success without error", func(t *testing.T) {
		eventID := "event-1"
		userID := "user-1"
		event := &GroupEvent{ID: eventID, Title: "Updated Title"}

		existing := &GroupEvent{ID: eventID, HostID: userID}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(existing, nil).Once()
		mockRepo.On("UpdateEvent", mock.Anything, event).Return(nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()

		updatedEvent, err := svc.UpdateEvent(context.Background(), event, userID)

		assert.NoError(t, err)
		assert.NotNil(t, updatedEvent)
		assert.Equal(t, userID, event.UpdatedBy)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given unauthorized request, When calling GroupEventService UpdateEvent, Then it returns unauthorized error", func(t *testing.T) {
		eventID := "event-1"
		userID := "user-other"
		event := &GroupEvent{ID: eventID}

		existing := &GroupEvent{ID: eventID, HostID: "user-creator"}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(existing, nil).Once()

		_, err := svc.UpdateEvent(context.Background(), event, userID)

		assert.ErrorIs(t, err, apperror.ErrEventAccessDenied)
	})
}

func TestGroupEventService_ApplyToEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	mockTrip := new(tripmocks.MockTripService)
	mockAuth := new(authmocks.MockAuthService)
	mockDB := new(MockBeginner)
	svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)

	t.Run("Given valid setup, When calling GroupEventService ApplyToEvent, Then it returns success without error", func(t *testing.T) {
		eventID := "event-1"
		userID := "applicant-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}

		event := &GroupEvent{ID: eventID, Status: "open"}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, userID).Return(&auth.User{DisplayName: "Applicant"}, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.NoError(t, err)
		assert.Equal(t, userID, app.CreatedBy)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given EventNotOpen, When calling GroupEventService ApplyToEvent, Then it behaves as expected", func(t *testing.T) {
		eventID := "event-1"
		app := &GroupEventApplication{EventID: eventID}

		event := &GroupEvent{ID: eventID, Status: "closed"}
		mockRepo.On("GetEventByID", mock.Anything, eventID, mock.Anything).Return(event, nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "無法報名")
	})
}
