package groupevent

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockGroupEventRepository struct {
	mock.Mock
}

func (m *MockGroupEventRepository) CreateEvent(ctx context.Context, event *GroupEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

func (m *MockGroupEventRepository) GetEventByID(ctx context.Context, id string) (*GroupEvent, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*GroupEvent), args.Error(1)
}

func (m *MockGroupEventRepository) ListEvents(ctx context.Context, status *string, category *Category, creatorID *string, page int, limit int, search string) ([]*GroupEvent, int, bool, error) {
	args := m.Called(ctx, status, category, creatorID, page, limit, search)
	if args.Get(0) == nil {
		return nil, 0, false, args.Error(3)
	}
	return args.Get(0).([]*GroupEvent), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *MockGroupEventRepository) UpdateEvent(ctx context.Context, event *GroupEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

func (m *MockGroupEventRepository) DeleteEvent(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockGroupEventRepository) ApplyToEvent(ctx context.Context, app *GroupEventApplication) error {
	args := m.Called(ctx, app)
	return args.Error(0)
}

func (m *MockGroupEventRepository) ListApplications(ctx context.Context, eventID string) ([]*GroupEventApplication, error) {
	args := m.Called(ctx, eventID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*GroupEventApplication), args.Error(1)
}

func (m *MockGroupEventRepository) UpdateApplicationStatus(ctx context.Context, eventID, userID, status, updatedBy string) error {
	args := m.Called(ctx, eventID, userID, status, updatedBy)
	return args.Error(0)
}

func (m *MockGroupEventRepository) AddComment(ctx context.Context, comment *GroupEventComment) error {
	args := m.Called(ctx, comment)
	return args.Error(0)
}

func (m *MockGroupEventRepository) ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error) {
	args := m.Called(ctx, eventID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*GroupEventComment), args.Error(1)
}

func (m *MockGroupEventRepository) DeleteComment(ctx context.Context, commentID string, userID string) error {
	args := m.Called(ctx, commentID, userID)
	return args.Error(0)
}

func (m *MockGroupEventRepository) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	args := m.Called(ctx, eventID, userID)
	return args.Bool(0), args.Error(1)
}

func (m *MockGroupEventRepository) UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error {
	args := m.Called(ctx, eventID, tripID, userID)
	return args.Error(0)
}

func (m *MockGroupEventRepository) UpdateTripSnapshot(ctx context.Context, eventID string, snapshot *TripSnapshot, userID string) error {
	args := m.Called(ctx, eventID, snapshot, userID)
	return args.Error(0)
}
