package groupevent

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/apperror"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGroupEventService_CreateEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	svc := NewGroupEventService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		event := &GroupEvent{
			Title:     "Hiking Trip",
			CreatedBy: "user-1",
		}
		mockRepo.On("CreateEvent", mock.Anything, event).Return(nil).Once()

		err := svc.CreateEvent(context.Background(), event)

		assert.NoError(t, err)
		assert.Equal(t, "open", event.Status)
		mockRepo.AssertExpectations(t)
	})

	t.Run("EmptyTitle", func(t *testing.T) {
		event := &GroupEvent{Title: ""}
		err := svc.CreateEvent(context.Background(), event)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "活動標題為必填")
	})
}

func TestGroupEventService_UpdateEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	svc := NewGroupEventService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		eventID := "event-1"
		userID := "user-1"
		event := &GroupEvent{ID: eventID, Title: "Updated Title"}
		
		existing := &GroupEvent{ID: eventID, CreatedBy: userID}
		mockRepo.On("GetEventByID", mock.Anything, eventID).Return(existing, nil).Once()
		mockRepo.On("UpdateEvent", mock.Anything, event).Return(nil).Once()

		err := svc.UpdateEvent(context.Background(), event, userID)

		assert.NoError(t, err)
		assert.Equal(t, userID, event.UpdatedBy)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Unauthorized", func(t *testing.T) {
		eventID := "event-1"
		userID := "user-other"
		event := &GroupEvent{ID: eventID}
		
		existing := &GroupEvent{ID: eventID, CreatedBy: "user-creator"}
		mockRepo.On("GetEventByID", mock.Anything, eventID).Return(existing, nil).Once()

		err := svc.UpdateEvent(context.Background(), event, userID)

		assert.ErrorIs(t, err, apperror.ErrEventAccessDenied)
	})
}

func TestGroupEventService_ApplyToEvent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockGroupEventRepository)
	svc := NewGroupEventService(logger, mockRepo)

	t.Run("Success", func(t *testing.T) {
		eventID := "event-1"
		userID := "applicant-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}
		
		event := &GroupEvent{ID: eventID, Status: "open"}
		mockRepo.On("GetEventByID", mock.Anything, eventID).Return(event, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.NoError(t, err)
		assert.Equal(t, userID, app.CreatedBy)
		mockRepo.AssertExpectations(t)
	})

	t.Run("EventNotOpen", func(t *testing.T) {
		eventID := "event-1"
		app := &GroupEventApplication{EventID: eventID}
		
		event := &GroupEvent{ID: eventID, Status: "closed"}
		mockRepo.On("GetEventByID", mock.Anything, eventID).Return(event, nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "無法報名")
	})
}
