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

func (m *MockFavoriteRepository) ListByUserID(ctx context.Context, userID string, page int, limit int) ([]*Favorite, int, bool, error) {
	args := m.Called(ctx, userID, page, limit)
	if args.Get(0) == nil {
		return nil, 0, false, args.Error(3)
	}
	return args.Get(0).([]*Favorite), args.Int(1), args.Bool(2), args.Error(3)
}

func (m *MockFavoriteRepository) DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error {
	args := m.Called(ctx, targetID, userID)
	return args.Error(0)
}

func (m *MockFavoriteRepository) BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error {
	args := m.Called(ctx, userID, items)
	return args.Error(0)
}
