package trip

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockTripService struct {
	mock.Mock
}

func (m *MockTripService) CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*Trip, error) {
	args := m.Called(ctx, userID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripService) GetTrip(ctx context.Context, tripID, userID string) (*Trip, error) {
	args := m.Called(ctx, tripID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripService) ListTrips(ctx context.Context, userID string) ([]*Trip, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*Trip), args.Error(1)
}

func (m *MockTripService) UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*Trip, error) {
	args := m.Called(ctx, tripID, userID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripService) DeleteTrip(ctx context.Context, tripID, userID string) error {
	args := m.Called(ctx, tripID, userID)
	return args.Error(0)
}

func (m *MockTripService) ListMembers(ctx context.Context, tripID, userID string) ([]*TripMember, error) {
	args := m.Called(ctx, tripID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripMember), args.Error(1)
}

func (m *MockTripService) AddMember(ctx context.Context, tripID, userID, email string) (*TripMember, error) {
	args := m.Called(ctx, tripID, userID, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripMember), args.Error(1)
}

func (m *MockTripService) RemoveMember(ctx context.Context, tripID, actionUserID, userID string) error {
	args := m.Called(ctx, tripID, actionUserID, userID)
	return args.Error(0)
}

func (m *MockTripService) ListItinerary(ctx context.Context, tripID, userID string) ([]*ItineraryItem, error) {
	args := m.Called(ctx, tripID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*ItineraryItem), args.Error(1)
}

func (m *MockTripService) AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error) {
	args := m.Called(ctx, tripID, userID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockTripService) UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error) {
	args := m.Called(ctx, tripID, itemID, userID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockTripService) DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error {
	args := m.Called(ctx, tripID, itemID, userID)
	return args.Error(0)
}
