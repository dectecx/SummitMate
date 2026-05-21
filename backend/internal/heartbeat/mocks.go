package heartbeat

import (
	"context"
	"github.com/stretchr/testify/mock"
)

type MockHeartbeatRepository struct{ mock.Mock }

func (m *MockHeartbeatRepository) Upsert(ctx context.Context, hb *Heartbeat) error {
	args := m.Called(ctx, hb)
	return args.Error(0)
}

func (m *MockHeartbeatRepository) GetByUserID(ctx context.Context, userID string) (*Heartbeat, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Heartbeat), args.Error(1)
}
