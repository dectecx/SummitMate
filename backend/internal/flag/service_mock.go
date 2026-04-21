package flag

import (
	"context"

	"github.com/stretchr/testify/mock"
)

// MockService is a mock implementation of the flag.Service interface.
type MockService struct {
	mock.Mock
}

func (m *MockService) IsEnabled(ctx context.Context, key string) bool {
	args := m.Called(ctx, key)
	return args.Bool(0)
}

func (m *MockService) SetFlag(ctx context.Context, key string, value bool) error {
	args := m.Called(ctx, key, value)
	return args.Error(0)
}

func (m *MockService) GetAll(ctx context.Context) ([]Flag, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]Flag), args.Error(1)
}
