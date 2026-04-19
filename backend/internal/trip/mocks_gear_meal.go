package trip

import (
	"context"
	"github.com/stretchr/testify/mock"
)

// MockTripGearRepository is a mock implementation of the TripGearRepository interface
type MockTripGearRepository struct {
	mock.Mock
}

func (m *MockTripGearRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripGearItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Create(ctx context.Context, gear *TripGearItem) (*TripGearItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) GetByID(ctx context.Context, id string, tripID string) (*TripGearItem, error) {
	args := m.Called(ctx, id, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Update(ctx context.Context, gear *TripGearItem) (*TripGearItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Delete(ctx context.Context, id string, tripID string) error {
	args := m.Called(ctx, id, tripID)
	return args.Error(0)
}

func (m *MockTripGearRepository) ReplaceAll(ctx context.Context, tripID string, gears []*TripGearItem) error {
	args := m.Called(ctx, tripID, gears)
	return args.Error(0)
}

// MockTripMealRepository is a mock implementation of the TripMealRepository interface
type MockTripMealRepository struct {
	mock.Mock
}

func (m *MockTripMealRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripMealItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Create(ctx context.Context, meal *TripMealItem) (*TripMealItem, error) {
	args := m.Called(ctx, meal)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) GetByID(ctx context.Context, id string, tripID string) (*TripMealItem, error) {
	args := m.Called(ctx, id, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Update(ctx context.Context, meal *TripMealItem) (*TripMealItem, error) {
	args := m.Called(ctx, meal)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Delete(ctx context.Context, id string, tripID string) error {
	args := m.Called(ctx, id, tripID)
	return args.Error(0)
}

func (m *MockTripMealRepository) ReplaceAll(ctx context.Context, tripID string, meals []*TripMealItem) error {
	args := m.Called(ctx, tripID, meals)
	return args.Error(0)
}
