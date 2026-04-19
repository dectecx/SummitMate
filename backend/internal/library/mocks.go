package library

import (
	"context"
	"github.com/stretchr/testify/mock"
)

// MockGearLibraryRepository is a mock implementation of the GearLibraryRepository interface
type MockGearLibraryRepository struct { mock.Mock }

func (m *MockGearLibraryRepository) Create(ctx context.Context, gear *GearLibraryItem) (*GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}
func (m *MockGearLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*GearLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}
func (m *MockGearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*GearLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).([]*GearLibraryItem), args.Error(1)
}
func (m *MockGearLibraryRepository) Update(ctx context.Context, gear *GearLibraryItem) (*GearLibraryItem, error) {
	args := m.Called(ctx, gear)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}
func (m *MockGearLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}
func (m *MockGearLibraryRepository) ReplaceAll(ctx context.Context, userID string, gears []*GearLibraryItem) error {
	args := m.Called(ctx, userID, gears)
	return args.Error(0)
}

// MockMealLibraryRepository is a mock implementation of the MealLibraryRepository interface
type MockMealLibraryRepository struct { mock.Mock }

func (m *MockMealLibraryRepository) Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}
func (m *MockMealLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*MealLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}
func (m *MockMealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*MealLibraryItem, error) {
	args := m.Called(ctx, userID, includeArchived)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).([]*MealLibraryItem), args.Error(1)
}
func (m *MockMealLibraryRepository) Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}
func (m *MockMealLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}
func (m *MockMealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}
