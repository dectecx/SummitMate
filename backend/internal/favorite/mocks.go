package favorite

import (
	"context"

	"github.com/stretchr/testify/mock"
)

type MockFavoriteRepository struct {
	mock.Mock
}

func (m *MockFavoriteRepository) Create(ctx context.Context, fav *Favorite) error {
	args := m.Called(ctx, fav)
	return args.Error(0)
}

func (m *MockFavoriteRepository) ListByUserID(ctx context.Context, userID string) ([]*Favorite, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*Favorite), args.Error(1)
}

func (m *MockFavoriteRepository) DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error {
	args := m.Called(ctx, targetID, userID)
	return args.Error(0)
}

func (m *MockFavoriteRepository) BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}
