package repository

import (
	"context"
	"summitmate/internal/model"

	"github.com/stretchr/testify/mock"
)

// MockUserRepository is a mock implementation of the UserRepository interface
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(ctx context.Context, user *model.User) (*model.User, error) {
	args := m.Called(ctx, user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.User), args.Error(1)
}

func (m *MockUserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.User), args.Error(1)
}

func (m *MockUserRepository) GetByID(ctx context.Context, id string) (*model.User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.User), args.Error(1)
}

func (m *MockUserRepository) Update(ctx context.Context, id string, displayName, avatar *string) (*model.User, error) {
	args := m.Called(ctx, id, displayName, avatar)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.User), args.Error(1)
}

func (m *MockUserRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserRepository) SoftDelete(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserRepository) SetVerified(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

// MockTripRepository is a mock implementation of the TripRepository interface
type MockTripRepository struct {
	mock.Mock
}

func (m *MockTripRepository) Create(ctx context.Context, trip *model.Trip) (*model.Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.Trip), args.Error(1)
}

func (m *MockTripRepository) GetByID(ctx context.Context, id string) (*model.Trip, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.Trip), args.Error(1)
}

func (m *MockTripRepository) ListByUserID(ctx context.Context, userID string) ([]*model.Trip, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.Trip), args.Error(1)
}

func (m *MockTripRepository) Update(ctx context.Context, trip *model.Trip) (*model.Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.Trip), args.Error(1)
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

func (m *MockTripMemberRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripMember, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.TripMember), args.Error(1)
}

// MockItineraryRepository is a mock implementation of the ItineraryRepository interface
type MockItineraryRepository struct {
	mock.Mock
}

func (m *MockItineraryRepository) Create(ctx context.Context, item *model.ItineraryItem) (*model.ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) GetByID(ctx context.Context, id string) (*model.ItineraryItem, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.ItineraryItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) Update(ctx context.Context, item *model.ItineraryItem) (*model.ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

// MockGearLibraryRepository is a mock implementation of the GearLibraryRepository interface
type MockGearLibraryRepository struct {
	mock.Mock
}

func (m *MockGearLibraryRepository) Create(ctx context.Context, gear *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*model.GearLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*model.GearLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) Update(ctx context.Context, gear *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockGearLibraryRepository) ReplaceAll(ctx context.Context, userID string, gears []*model.GearLibraryItem) error {
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

func (m *MockMealLibraryRepository) Create(ctx context.Context, item *model.MealLibraryItem) (*model.MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*model.MealLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*model.MealLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*model.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) Update(ctx context.Context, item *model.MealLibraryItem) (*model.MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*model.MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockMealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*model.MealLibraryItem) error {
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
