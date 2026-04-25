package library

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockGearLibraryRepository struct {
	mock.Mock
}

func (m *MockGearLibraryRepository) Create(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) GetByID(ctx context.Context, id, userID string) (*GearLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*GearLibraryItem, int, bool, error) {
	args := m.Called(ctx, userID, includeArchived, page, limit, search)
	if args.Get(0) == nil {
		return nil, 0, false, args.Error(3)
	}
	return args.Get(0).([]*GearLibraryItem), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *MockGearLibraryRepository) Update(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*GearLibraryItem), args.Error(1)
}

func (m *MockGearLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*GearLibraryItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}

func (m *MockGearLibraryRepository) Delete(ctx context.Context, id, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

type MockMealLibraryRepository struct {
	mock.Mock
}

func (m *MockMealLibraryRepository) Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) GetByID(ctx context.Context, id, userID string) (*MealLibraryItem, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*MealLibraryItem, int, bool, error) {
	args := m.Called(ctx, userID, includeArchived, page, limit, search)
	if args.Get(0) == nil {
		return nil, 0, false, args.Error(3)
	}
	return args.Get(0).([]*MealLibraryItem), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *MockMealLibraryRepository) Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*MealLibraryItem), args.Error(1)
}

func (m *MockMealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}

func (m *MockMealLibraryRepository) Delete(ctx context.Context, id, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}
