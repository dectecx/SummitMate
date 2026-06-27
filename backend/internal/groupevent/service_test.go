package groupevent

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	"summitmate/internal/trip"
	tripmocks "summitmate/internal/trip/mocks"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
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

type MockTx struct {
	mock.Mock
}

func (m *MockTx) Begin(ctx context.Context) (pgx.Tx, error)   { return nil, nil }
func (m *MockTx) Commit(ctx context.Context) error             { return m.Called(ctx).Error(0) }
func (m *MockTx) Rollback(ctx context.Context) error           { return m.Called(ctx).Error(0) }
func (m *MockTx) LargeObjects() pgx.LargeObjects               { return pgx.LargeObjects{} }
func (m *MockTx) Conn() *pgx.Conn                              { return nil }
func (m *MockTx) SendBatch(ctx context.Context, b *pgx.Batch) pgx.BatchResults { return nil }
func (m *MockTx) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return 0, nil
}
func (m *MockTx) Prepare(ctx context.Context, name, sql string) (*pgconn.StatementDescription, error) {
	return nil, nil
}
func (m *MockTx) Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
func (m *MockTx) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	return nil, nil
}
func (m *MockTx) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row { return nil }

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
		}
		mockRepo.On("CreateEvent", mock.Anything, event).Return(nil).Once()

		err := svc.CreateEvent(context.Background(), event)

		assert.NoError(t, err)
		assert.Equal(t, "open", event.Status)
		assert.Equal(t, "user-1", event.CreatedBy)
		assert.Equal(t, "user-1", event.UpdatedBy)
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

	newSetup := func() (*MockGroupEventRepository, *tripmocks.MockTripService, *authmocks.MockAuthService, *MockBeginner, *MockTx, GroupEventService) {
		mockRepo := new(MockGroupEventRepository)
		mockTrip := new(tripmocks.MockTripService)
		mockAuth := new(authmocks.MockAuthService)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)
		return mockRepo, mockTrip, mockAuth, mockDB, mockTx, svc
	}

	t.Run("Given approval not required and no linked trip, When calling ApplyToEvent, Then it creates application atomically", func(t *testing.T) {
		mockRepo, _, mockAuth, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "applicant-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}

		event := &GroupEvent{ID: eventID, Status: "open", ApprovalRequired: false}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, userID).Return(&auth.User{DisplayName: "Applicant"}, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.NoError(t, err)
		assert.Equal(t, ApplicationStatusApproved, app.Status)
		assert.Equal(t, userID, app.CreatedBy)
		mockRepo.AssertExpectations(t)
		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given approval not required and linked trip, When calling ApplyToEvent, Then it atomically creates application and adds trip member", func(t *testing.T) {
		mockRepo, mockTrip, mockAuth, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "applicant-1"
		hostID := "host-1"
		tripID := "trip-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}

		event := &GroupEvent{ID: eventID, Status: "open", ApprovalRequired: false, HostID: hostID, CreatedBy: hostID, LinkedTripID: &tripID}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, userID).Return(&auth.User{DisplayName: "Applicant"}, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()
		mockTrip.On("AddMember", mock.Anything, tripID, hostID, userID).Return(&trip.TripMember{UserID: userID}, nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.NoError(t, err)
		assert.Equal(t, ApplicationStatusApproved, app.Status)
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given approval not required and linked trip, When AddMember fails, Then it rolls back application creation", func(t *testing.T) {
		mockRepo, mockTrip, mockAuth, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "applicant-1"
		tripID := "trip-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}

		event := &GroupEvent{ID: eventID, Status: "open", ApprovalRequired: false, LinkedTripID: &tripID}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, userID).Return(&auth.User{DisplayName: "Applicant"}, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()
		mockTrip.On("AddMember", mock.Anything, tripID, mock.Anything, userID).Return((*trip.TripMember)(nil), errors.New("trip permission denied")).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "trip permission denied")
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given approval required, When calling ApplyToEvent, Then it creates pending application", func(t *testing.T) {
		mockRepo, _, mockAuth, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "applicant-1"
		app := &GroupEventApplication{EventID: eventID, UserID: userID}

		event := &GroupEvent{ID: eventID, Status: "open", ApprovalRequired: true}
		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, userID).Return(&auth.User{DisplayName: "Applicant"}, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ApplyToEvent", mock.Anything, app).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.NoError(t, err)
		assert.Equal(t, ApplicationStatusPending, app.Status)
		mockRepo.AssertExpectations(t)
		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given event not open, When calling ApplyToEvent, Then it returns error before transaction", func(t *testing.T) {
		mockRepo, _, _, mockDB, _, svc := newSetup()
		eventID := "event-1"
		app := &GroupEventApplication{EventID: eventID}

		event := &GroupEvent{ID: eventID, Status: "closed"}
		mockRepo.On("GetEventByID", mock.Anything, eventID, mock.Anything).Return(event, nil).Once()

		err := svc.ApplyToEvent(context.Background(), app)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "無法報名")
		mockDB.AssertNotCalled(t, "Begin", mock.Anything)
	})
}

func TestGroupEventService_ProcessApplication(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	newSetup := func() (*MockGroupEventRepository, *tripmocks.MockTripService, *MockBeginner, *MockTx, GroupEventService) {
		mockRepo := new(MockGroupEventRepository)
		mockTrip := new(tripmocks.MockTripService)
		mockAuth := new(authmocks.MockAuthService)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)
		return mockRepo, mockTrip, mockDB, mockTx, svc
	}

	t.Run("Given approved status with linked trip, When calling ProcessApplication, Then it atomically updates status and adds trip member", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		executorID := "host-1"
		tripID := "trip-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: "user-1"}
		event := &GroupEvent{ID: "event-1", HostID: executorID, LinkedTripID: &tripID}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", executorID).Return(event, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("UpdateApplicationStatus", mock.Anything, appID, ApplicationStatusApproved, "", executorID).Return(nil).Once()
		mockTrip.On("AddMember", mock.Anything, tripID, executorID, "user-1").Return(&trip.TripMember{UserID: "user-1"}, nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ProcessApplication(context.Background(), appID, ApplicationStatusApproved, "", executorID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given approved status with linked trip, When AddMember fails, Then it rolls back status update", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		executorID := "host-1"
		tripID := "trip-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: "user-1"}
		event := &GroupEvent{ID: "event-1", HostID: executorID, LinkedTripID: &tripID}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", executorID).Return(event, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("UpdateApplicationStatus", mock.Anything, appID, ApplicationStatusApproved, "", executorID).Return(nil).Once()
		mockTrip.On("AddMember", mock.Anything, tripID, executorID, "user-1").Return((*trip.TripMember)(nil), errors.New("trip full")).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.ProcessApplication(context.Background(), appID, ApplicationStatusApproved, "", executorID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "trip full")
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given rejected status with linked trip, When calling ProcessApplication, Then it atomically updates status and removes trip member", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		executorID := "host-1"
		tripID := "trip-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: "user-1"}
		event := &GroupEvent{ID: "event-1", HostID: executorID, LinkedTripID: &tripID}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", executorID).Return(event, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("UpdateApplicationStatus", mock.Anything, appID, ApplicationStatusRejected, "not qualified", executorID).Return(nil).Once()
		mockTrip.On("RemoveMember", mock.Anything, tripID, executorID, "user-1").Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ProcessApplication(context.Background(), appID, ApplicationStatusRejected, "not qualified", executorID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given no linked trip, When calling ProcessApplication, Then it updates status without trip operations", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		executorID := "host-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: "user-1"}
		event := &GroupEvent{ID: "event-1", HostID: executorID, LinkedTripID: nil}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", executorID).Return(event, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("UpdateApplicationStatus", mock.Anything, appID, ApplicationStatusApproved, "", executorID).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.ProcessApplication(context.Background(), appID, ApplicationStatusApproved, "", executorID)

		assert.NoError(t, err)
		mockTrip.AssertNotCalled(t, "AddMember", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockRepo.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})
}

func TestGroupEventService_UpdateTripLink(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	newSetup := func() (*MockGroupEventRepository, *tripmocks.MockTripService, *MockBeginner, *MockTx, GroupEventService) {
		mockRepo := new(MockGroupEventRepository)
		mockTrip := new(tripmocks.MockTripService)
		mockAuth := new(authmocks.MockAuthService)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)
		return mockRepo, mockTrip, mockDB, mockTx, svc
	}

	t.Run("Given event with old linked trip and new trip, When calling UpdateTripLink, Then it atomically migrates members", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "host-1"
		oldTripID := "trip-old"
		newTripID := "trip-new"

		event := &GroupEvent{ID: eventID, HostID: userID, LinkedTripID: &oldTripID}
		newTrip := &trip.Trip{ID: newTripID}
		apps := []*GroupEventApplication{
			{UserID: "member-1", Status: ApplicationStatusApproved},
			{UserID: "member-2", Status: ApplicationStatusPending},
		}

		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockTrip.On("GetTrip", mock.Anything, newTripID, userID).Return(newTrip, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ListApplications", mock.Anything, eventID).Return(apps, nil).Once()
		mockTrip.On("BatchRemoveMembers", mock.Anything, oldTripID, userID, []string{"member-1"}).Return(nil).Once()
		mockTrip.On("BatchAddMembers", mock.Anything, newTripID, userID, []string{"member-1"}).Return(nil).Once()
		mockRepo.On("UpdateTripLink", mock.Anything, eventID, &newTripID, userID).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.UpdateTripLink(context.Background(), eventID, &newTripID, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given event with old linked trip, When BatchRemoveMembers fails, Then it rolls back UpdateTripLink", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "host-1"
		oldTripID := "trip-old"
		newTripID := "trip-new"

		event := &GroupEvent{ID: eventID, HostID: userID, LinkedTripID: &oldTripID}
		newTrip := &trip.Trip{ID: newTripID}
		apps := []*GroupEventApplication{
			{UserID: "member-1", Status: ApplicationStatusApproved},
		}

		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockTrip.On("GetTrip", mock.Anything, newTripID, userID).Return(newTrip, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ListApplications", mock.Anything, eventID).Return(apps, nil).Once()
		mockTrip.On("BatchRemoveMembers", mock.Anything, oldTripID, userID, []string{"member-1"}).Return(errors.New("remove failed")).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.UpdateTripLink(context.Background(), eventID, &newTripID, userID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "remove failed")
		mockRepo.AssertNotCalled(t, "UpdateTripLink", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockTrip.AssertNotCalled(t, "BatchAddMembers", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given event with no existing linked trip, When calling UpdateTripLink, Then it updates link without member migration", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		eventID := "event-1"
		userID := "host-1"
		newTripID := "trip-new"

		event := &GroupEvent{ID: eventID, HostID: userID, LinkedTripID: nil}
		newTrip := &trip.Trip{ID: newTripID}

		mockRepo.On("GetEventByID", mock.Anything, eventID, userID).Return(event, nil).Once()
		mockTrip.On("GetTrip", mock.Anything, newTripID, userID).Return(newTrip, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("UpdateTripLink", mock.Anything, eventID, &newTripID, userID).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.UpdateTripLink(context.Background(), eventID, &newTripID, userID)

		assert.NoError(t, err)
		mockTrip.AssertNotCalled(t, "BatchRemoveMembers", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockTrip.AssertNotCalled(t, "BatchAddMembers", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockRepo.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})
}

func TestGroupEventService_CancelApplication(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	newSetup := func() (*MockGroupEventRepository, *tripmocks.MockTripService, *MockBeginner, *MockTx, GroupEventService) {
		mockRepo := new(MockGroupEventRepository)
		mockTrip := new(tripmocks.MockTripService)
		mockAuth := new(authmocks.MockAuthService)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewGroupEventService(logger, mockDB, mockRepo, mockTrip, mockAuth)
		return mockRepo, mockTrip, mockDB, mockTx, svc
	}

	t.Run("Given approved application with linked trip, When cancelling, Then it atomically deletes application and removes trip member", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		userID := "user-1"
		tripID := "trip-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: userID, Status: ApplicationStatusApproved}
		event := &GroupEvent{ID: "event-1", CreatedBy: "host-1", LinkedTripID: &tripID}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("DeleteApplication", mock.Anything, appID).Return(nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", userID).Return(event, nil).Once()
		mockTrip.On("RemoveMember", mock.Anything, tripID, "host-1", userID).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.CancelApplication(context.Background(), appID, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given approved application with linked trip, When RemoveMember fails, Then it rolls back application deletion", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		userID := "user-1"
		tripID := "trip-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: userID, Status: ApplicationStatusApproved}
		event := &GroupEvent{ID: "event-1", CreatedBy: "host-1", LinkedTripID: &tripID}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("DeleteApplication", mock.Anything, appID).Return(nil).Once()
		mockRepo.On("GetEventByID", mock.Anything, "event-1", userID).Return(event, nil).Once()
		mockTrip.On("RemoveMember", mock.Anything, tripID, "host-1", userID).Return(errors.New("remove failed")).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.CancelApplication(context.Background(), appID, userID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "remove failed")
		mockRepo.AssertExpectations(t)
		mockTrip.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given pending application, When cancelling, Then it deletes application without trip operations", func(t *testing.T) {
		mockRepo, mockTrip, mockDB, mockTx, svc := newSetup()
		appID := "app-1"
		userID := "user-1"

		app := &GroupEventApplication{ID: appID, EventID: "event-1", UserID: userID, Status: ApplicationStatusPending}

		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()
		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("DeleteApplication", mock.Anything, appID).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.CancelApplication(context.Background(), appID, userID)

		assert.NoError(t, err)
		mockTrip.AssertNotCalled(t, "RemoveMember", mock.Anything, mock.Anything, mock.Anything, mock.Anything)
		mockRepo.AssertExpectations(t)
		mockTx.AssertExpectations(t)
	})

	t.Run("Given another user's application, When cancelling, Then it returns access denied before transaction", func(t *testing.T) {
		mockRepo, _, mockDB, _, svc := newSetup()
		appID := "app-1"
		userID := "user-other"

		app := &GroupEventApplication{ID: appID, UserID: "user-1", Status: ApplicationStatusApproved}
		mockRepo.On("GetApplicationByID", mock.Anything, appID).Return(app, nil).Once()

		err := svc.CancelApplication(context.Background(), appID, userID)

		require.Error(t, err)
		var appErr *apperror.AppError
		require.True(t, errors.As(err, &appErr))
		assert.Equal(t, "permission_denied", appErr.Code)
		mockDB.AssertNotCalled(t, "Begin", mock.Anything)
	})
}
