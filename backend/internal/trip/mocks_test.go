package trip

import (
	"context"

	"github.com/stretchr/testify/mock"
)

// MockTripRepository is a mock implementation of the TripRepository interface
type MockTripRepository struct {
	mock.Mock
}

func (m *MockTripRepository) Create(ctx context.Context, trip *Trip) (*Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) GetByID(ctx context.Context, id string) (*Trip, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) ListByUserID(ctx context.Context, userID string) ([]*Trip, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*Trip), args.Error(1)
}

func (m *MockTripRepository) Update(ctx context.Context, trip *Trip) (*Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

// MockTripMemberRepository is a mock implementation of the TripMemberRepository interface
type MockTripMemberRepository struct {
	mock.Mock
}

func (m *MockTripMemberRepository) AddMember(ctx context.Context, tripID, userID string) error {
	args := m.Called(ctx, tripID, userID)
	return args.Error(0)
}

func (m *MockTripMemberRepository) RemoveMember(ctx context.Context, tripID, userID string) error {
	args := m.Called(ctx, tripID, userID)
	return args.Error(0)
}

func (m *MockTripMemberRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripMember, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripMember), args.Error(1)
}

// MockItineraryRepository is a mock implementation of the ItineraryRepository interface
type MockItineraryRepository struct {
	mock.Mock
}

func (m *MockItineraryRepository) Create(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) GetByID(ctx context.Context, id string) (*ItineraryItem, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) ListByTripID(ctx context.Context, tripID string) ([]*ItineraryItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) Update(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}


