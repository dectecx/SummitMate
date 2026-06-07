package weather

import (
	"bytes"
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
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

type MockTx struct {
	mock.Mock
}

func (m *MockTx) Begin(ctx context.Context) (pgx.Tx, error) { return nil, nil }
func (m *MockTx) Commit(ctx context.Context) error          { return m.Called(ctx).Error(0) }
func (m *MockTx) Rollback(ctx context.Context) error        { return m.Called(ctx).Error(0) }
func (m *MockTx) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return 0, nil
}
func (m *MockTx) SendBatch(ctx context.Context, b *pgx.Batch) pgx.BatchResults { return nil }
func (m *MockTx) LargeObjects() pgx.LargeObjects                               { return pgx.LargeObjects{} }
func (m *MockTx) Prepare(ctx context.Context, name, sql string) (*pgconn.StatementDescription, error) {
	return nil, nil
}
func (m *MockTx) Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
func (m *MockTx) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	return nil, nil
}
func (m *MockTx) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	return nil
}
func (m *MockTx) Conn() *pgx.Conn { return nil }

type RoundTripFunc func(req *http.Request) *http.Response

func (f RoundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req), nil
}

func TestWeatherService_ListByLocation(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockWeatherRepository)
	mockDB := new(MockBeginner)
	svc := NewWeatherService(logger, mockDB, mockRepo, http.DefaultClient, "key", []string{"玉山"})

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

func TestWeatherService_ListAll(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockWeatherRepository)
	mockDB := new(MockBeginner)
	svc := NewWeatherService(logger, mockDB, mockRepo, http.DefaultClient, "key", []string{"玉山"})

	t.Run("Given valid setup, When calling WeatherService ListAll, Then it returns success without error", func(t *testing.T) {
		expected := []WeatherRecord{
			{Location: "玉山", Temp: 15.5},
		}
		mockRepo.On("ListAll", mock.Anything).Return(expected, nil).Once()

		result, err := svc.ListAll(context.Background())

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

func TestWeatherService_FetchAndStore(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given CWA API key is empty, When calling FetchAndStore, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockWeatherRepository)
		mockDB := new(MockBeginner)
		svc := NewWeatherService(logger, mockDB, mockRepo, http.DefaultClient, "", []string{"玉山"})

		err := svc.FetchAndStore(context.Background())
		assert.ErrorContains(t, err, "CWA_API_KEY 未設定")
	})

	t.Run("Given successful CWA API response and DB insert, When calling FetchAndStore, Then it completes successfully", func(t *testing.T) {
		mockRepo := new(MockWeatherRepository)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)

		// Mock JSON response matching cwaResponse structure
		jsonResponse := `{
			"cwaopendata": {
				"Dataset": {
					"DatasetInfo": {
						"IssueTime": "2026-06-07T14:20:00+08:00"
					},
					"Locations": {
						"Location": [
							{
								"LocationName": "玉山",
								"WeatherElement": [
									{
										"ElementName": "平均溫度",
										"Time": [
											{
												"StartTime": "2026-06-07T12:00:00+08:00",
												"EndTime": "2026-06-07T18:00:00+08:00",
												"ElementValue": {
													"Temperature": "12.5"
												}
											}
										]
									}
								]
							}
						]
					}
				}
			}
		}`

		client := &http.Client{
			Transport: RoundTripFunc(func(req *http.Request) *http.Response {
				return &http.Response{
					StatusCode: http.StatusOK,
					Body:       io.NopCloser(bytes.NewBufferString(jsonResponse)),
					Header:     make(http.Header),
				}
			}),
		}

		svc := NewWeatherService(logger, mockDB, mockRepo, client, "valid-key", []string{"玉山"})

		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ReplaceAll", mock.Anything, mock.MatchedBy(func(recs []WeatherRecord) bool {
			return len(recs) == 1 && recs[0].Location == "玉山" && recs[0].Temp == 12.5
		})).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.FetchAndStore(context.Background())
		assert.NoError(t, err)

		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given CWA API returns non-200, When calling FetchAndStore, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockWeatherRepository)
		mockDB := new(MockBeginner)

		client := &http.Client{
			Transport: RoundTripFunc(func(req *http.Request) *http.Response {
				return &http.Response{
					StatusCode: http.StatusInternalServerError,
					Body:       io.NopCloser(bytes.NewBufferString("Internal Error")),
				}
			}),
		}

		svc := NewWeatherService(logger, mockDB, mockRepo, client, "valid-key", []string{"玉山"})

		err := svc.FetchAndStore(context.Background())
		assert.ErrorContains(t, err, "unexpected status code: 500")
	})

	t.Run("Given DB replace fails, When calling FetchAndStore, Then transaction is rolled back and returns error", func(t *testing.T) {
		mockRepo := new(MockWeatherRepository)
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)

		jsonResponse := `{"cwaopendata": {"Dataset": {"DatasetInfo": {"IssueTime": ""}, "Locations": {"Location": []}}}}`
		client := &http.Client{
			Transport: RoundTripFunc(func(req *http.Request) *http.Response {
				return &http.Response{
					StatusCode: http.StatusOK,
					Body:       io.NopCloser(bytes.NewBufferString(jsonResponse)),
				}
			}),
		}

		svc := NewWeatherService(logger, mockDB, mockRepo, client, "valid-key", []string{"玉山"})

		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("ReplaceAll", mock.Anything, mock.Anything).Return(errors.New("db error")).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.FetchAndStore(context.Background())
		assert.ErrorContains(t, err, "db error")

		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
		mockRepo.AssertExpectations(t)
	})
}

