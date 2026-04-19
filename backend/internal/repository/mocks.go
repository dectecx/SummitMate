package repository

import (
	"context"
	"summitmate/internal/library"
	"summitmate/internal/model"

	"github.com/stretchr/testify/mock"
)


// MockGearLibraryRepository is a mock implementation of the GearLibraryRepository interface



// MockGearLibraryRepository is a mock implementation of the GearLibraryRepository interface
type MockGearLibraryRepository struct {
	mock.Mock
}

func (m *MockGearLibraryRepository) Create(ctx context.Context, gear *library.GearLibraryItem) (*library.GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*library.GearLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*library.GearLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*library.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) Update(ctx context.Context, gear *library.GearLibraryItem) (*library.GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockGearLibraryRepository) ReplaceAll(ctx context.Context, userID string, gears []*library.GearLibraryItem) error {
	args := m.Called(ctx, userID, gears)
	return args.Error(0)
}

// MockTripGearRepository is a mock implementation of the TripGearRepository interface
type MockTripGearRepository struct {
	mock.Mock
}

func (m *MockTripGearRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripGearItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Create(ctx context.Context, gear *model.TripGearItem) (*model.TripGearItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) GetByID(ctx context.Context, id string, tripID string) (*model.TripGearItem, error) {
	args := m.Called(ctx, id, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Update(ctx context.Context, gear *model.TripGearItem) (*model.TripGearItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripGearItem), args.Error(1)
}

func (m *MockTripGearRepository) Delete(ctx context.Context, id string, tripID string) error {
	args := m.Called(ctx, id, tripID)
	return args.Error(0)
}

func (m *MockTripGearRepository) ReplaceAll(ctx context.Context, tripID string, gears []*model.TripGearItem) error {
	args := m.Called(ctx, tripID, gears)
	return args.Error(0)
}

// MockMealLibraryRepository is a mock implementation of the MealLibraryRepository interface
type MockMealLibraryRepository struct {
	mock.Mock
}

func (m *MockMealLibraryRepository) Create(ctx context.Context, item *library.MealLibraryItem) (*library.MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*library.MealLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*library.MealLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*library.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) Update(ctx context.Context, item *library.MealLibraryItem) (*library.MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*library.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockMealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*library.MealLibraryItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}

// MockTripMealRepository is a mock implementation of the TripMealRepository interface
type MockTripMealRepository struct {
	mock.Mock
}

func (m *MockTripMealRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripMealItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Create(ctx context.Context, meal *model.TripMealItem) (*model.TripMealItem, error) {
	args := m.Called(ctx, meal)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) GetByID(ctx context.Context, id string, tripID string) (*model.TripMealItem, error) {
	args := m.Called(ctx, id, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Update(ctx context.Context, meal *model.TripMealItem) (*model.TripMealItem, error) {
	args := m.Called(ctx, meal)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.TripMealItem), args.Error(1)
}

func (m *MockTripMealRepository) Delete(ctx context.Context, id string, tripID string) error {
	args := m.Called(ctx, id, tripID)
	return args.Error(0)
}

func (m *MockTripMealRepository) ReplaceAll(ctx context.Context, tripID string, meals []*model.TripMealItem) error {
	args := m.Called(ctx, tripID, meals)
	return args.Error(0)
}

// MockWeatherRepository is a mock implementation of the WeatherRepository interface
type MockWeatherRepository struct {
	mock.Mock
}

func (m *MockWeatherRepository) ReplaceAll(ctx context.Context, records []model.WeatherRecord) error {
	args := m.Called(ctx, records)
	return args.Error(0)
}

func (m *MockWeatherRepository) ListAll(ctx context.Context) ([]model.WeatherRecord, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.WeatherRecord), args.Error(1)
}

func (m *MockWeatherRepository) ListByLocation(ctx context.Context, location string) ([]model.WeatherRecord, error) {
	args := m.Called(ctx, location)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]model.WeatherRecord), args.Error(1)
}

// MockHeartbeatRepository is a mock implementation of the HeartbeatRepository interface
type MockHeartbeatRepository struct {
	mock.Mock
}

func (m *MockHeartbeatRepository) Upsert(ctx context.Context, hb *model.Heartbeat) error {
	args := m.Called(ctx, hb)
	return args.Error(0)
}

// MockLogRepository is a mock implementation of the LogRepository interface
type MockLogRepository struct {
	mock.Mock
}

func (m *MockLogRepository) BatchCreate(ctx context.Context, deviceID, deviceName string, entries []model.LogEntry) (int, error) {
	args := m.Called(ctx, deviceID, deviceName, entries)
	return args.Int(0), args.Error(1)
}
