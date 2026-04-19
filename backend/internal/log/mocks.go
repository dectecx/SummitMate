package log
import (
	"context"
	"github.com/stretchr/testify/mock"
)
type MockLogRepository struct { mock.Mock }
func (m *MockLogRepository) BatchCreate(ctx context.Context, deviceID, deviceName string, entries []LogEntry) (int, error) {
	args := m.Called(ctx, deviceID, deviceName, entries)
	return args.Int(0), args.Error(1)
}
