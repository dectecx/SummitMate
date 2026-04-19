package weather
import (
	"context"
	"github.com/stretchr/testify/mock"
)
type MockWeatherRepository struct { mock.Mock }
func (m *MockWeatherRepository) ReplaceAll(ctx context.Context, records []WeatherRecord) error {
	args := m.Called(ctx, records)
	return args.Error(0)
}
func (m *MockWeatherRepository) ListAll(ctx context.Context) ([]WeatherRecord, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).([]WeatherRecord), args.Error(1)
}
func (m *MockWeatherRepository) ListByLocation(ctx context.Context, location string) ([]WeatherRecord, error) {
	args := m.Called(ctx, location)
	if args.Get(0) == nil { return nil, args.Error(1) }
	return args.Get(0).([]WeatherRecord), args.Error(1)
}
