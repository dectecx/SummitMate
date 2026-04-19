package heartbeat
import (
	"context"
	"github.com/stretchr/testify/mock"
)
type MockHeartbeatRepository struct { mock.Mock }
func (m *MockHeartbeatRepository) Upsert(ctx context.Context, hb *Heartbeat) error {
	args := m.Called(ctx, hb)
	return args.Error(0)
}
