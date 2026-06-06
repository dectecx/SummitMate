package weather

import (
	"context"
	"log/slog"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockBeginner struct {
	mock.Mock
}

func (m *MockBeginner) Begin(ctx context.Context) (pgx.Tx, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(pgx.Tx), args.Error(1)
}

func TestWeatherService_ListByLocation(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockWeatherRepository)
	mockDB := new(MockBeginner)
	svc := NewWeatherService(logger, mockDB, mockRepo, "key", []string{"玉山"})

	t.Run("Given valid setup, When calling WeatherService ListByLocation, Then it returns success without error", func(t *testing.T) {
		location := "玉山"
		expected := []WeatherRecord{
			{Location: location, Temp: 15.5},
		}
		mockRepo.On("ListByLocation", mock.Anything, location).Return(expected, nil).Once()

		result, err := svc.ListByLocation(context.Background(), location)

		assert.NoError(t, err)
		assert.Equal(t, expected, result)
		mockRepo.AssertExpectations(t)
	})
}

func TestWeatherService_Aggregate(t *testing.T) {
	t.Run("Given default context, When calling WeatherService Aggregate, Then it should perform successfully", func(t *testing.T) {
		logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
		svc := &weatherService{logger: logger}
	
		startTime := time.Now()
		endTime := startTime.Add(12 * time.Hour)
		issueTime := time.Now()
	
		rows := []rawRow{
			{Location: "玉山", StartTime: startTime, EndTime: endTime, ElementName: "平均溫度", Value: "10.5"},
			{Location: "玉山", StartTime: startTime, EndTime: endTime, ElementName: "天氣現象", Value: "多雲"},
			{Location: "玉山", StartTime: startTime, EndTime: endTime, ElementName: "12小時降雨機率", Value: "20"},
		}
	
		records := svc.aggregate(rows, &issueTime)
	
		assert.Len(t, records, 1)
		assert.Equal(t, "玉山", records[0].Location)
		assert.Equal(t, 10.5, records[0].Temp)
		assert.Equal(t, "多雲", records[0].Wx)
		assert.Equal(t, 20, records[0].PoP)
	})
}
