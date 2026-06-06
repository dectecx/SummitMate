package flag

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockFlagRepository 模擬 FlagRepository
type MockFlagRepository struct {
	mock.Mock
}

func (m *MockFlagRepository) GetByKey(ctx context.Context, key string) (*Flag, error) {
	args := m.Called(ctx, key)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Flag), args.Error(1)
}

func (m *MockFlagRepository) GetAll(ctx context.Context) ([]Flag, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]Flag), args.Error(1)
}

func (m *MockFlagRepository) Update(ctx context.Context, key string, value bool) error {
	args := m.Called(ctx, key, value)
	return args.Error(0)
}

func TestFlagService_IsEnabled_Cache(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFlagRepository)

	// NewFlagService 初始化時會調用一次 GetAll 載入 cache
	initialFlags := []Flag{
		{Key: "feature-a", Value: true},
		{Key: "feature-b", Value: false},
	}
	mockRepo.On("GetAll", mock.Anything).Return(initialFlags, nil).Once()

	svc := NewFlagService(mockRepo, logger)

	t.Run("Given GetFromCache, When calling FlagService IsEnabled Cache, Then it behaves as expected", func(t *testing.T) {
		// 呼叫 IsEnabled 時不需要調用 repo，因為已經被 cache
		valA := svc.IsEnabled(context.Background(), "feature-a")
		valB := svc.IsEnabled(context.Background(), "feature-b")

		assert.True(t, valA)
		assert.False(t, valB)
	})

	t.Run("Given CacheExpirationRefresh, When calling FlagService IsEnabled Cache, Then it behaves as expected", func(t *testing.T) {
		// 將 lastFetch 時間調為 10 分鐘前，使其過期
		impl := svc.(*flagService)
		impl.cacheMutex.Lock()
		impl.lastFetch = time.Now().Add(-10 * time.Minute)
		impl.cacheMutex.Unlock()

		// 預期 IsEnabled 會因為過期而再次呼叫 repo.GetAll 刷新
		refreshedFlags := []Flag{
			{Key: "feature-a", Value: false}, // 狀態變更
			{Key: "feature-b", Value: true},  // 狀態變更
		}
		mockRepo.On("GetAll", mock.Anything).Return(refreshedFlags, nil).Once()

		valA := svc.IsEnabled(context.Background(), "feature-a")
		valB := svc.IsEnabled(context.Background(), "feature-b")

		assert.False(t, valA)
		assert.True(t, valB)
	})

	t.Run("Given CacheRefreshErrorFallback, When calling FlagService IsEnabled Cache, Then it behaves as expected", func(t *testing.T) {
		// 再次讓快取過期
		impl := svc.(*flagService)
		impl.cacheMutex.Lock()
		impl.lastFetch = time.Now().Add(-10 * time.Minute)
		impl.cacheMutex.Unlock()

		// 預期呼叫 repo.GetAll 失敗，但因為 fallback 不應 crash，並維持舊的值
		mockRepo.On("GetAll", mock.Anything).Return(([]Flag)(nil), errors.New("db error")).Once()

		valB := svc.IsEnabled(context.Background(), "feature-b")
		assert.True(t, valB) // 應該還是回傳 true (上一次的快取結果)
	})

	mockRepo.AssertExpectations(t)
}

func TestFlagService_SetFlag(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFlagRepository)

	initialFlags := []Flag{
		{Key: "feature-x", Value: false},
	}
	mockRepo.On("GetAll", mock.Anything).Return(initialFlags, nil).Once()

	svc := NewFlagService(mockRepo, logger)

	t.Run("Given SuccessUpdateAndCacheWrite, When calling FlagService SetFlag, Then it behaves as expected", func(t *testing.T) {
		mockRepo.On("Update", mock.Anything, "feature-x", true).Return(nil).Once()

		err := svc.SetFlag(context.Background(), "feature-x", true)
		assert.NoError(t, err)

		// 驗證快取是否被即時更新，而不需要調用 repo.GetAll
		val := svc.IsEnabled(context.Background(), "feature-x")
		assert.True(t, val)
	})

	t.Run("Given UpdateError, When calling FlagService SetFlag, Then it behaves as expected", func(t *testing.T) {
		mockRepo.On("Update", mock.Anything, "feature-x", false).Return(errors.New("db error")).Once()

		err := svc.SetFlag(context.Background(), "feature-x", false)
		assert.Error(t, err)

		// 快取應該保持原樣 (還是 true)
		val := svc.IsEnabled(context.Background(), "feature-x")
		assert.True(t, val)
	})

	mockRepo.AssertExpectations(t)
}

func TestFlagService_GetAll(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFlagRepository)

	// NewFlagService init
	mockRepo.On("GetAll", mock.Anything).Return([]Flag{}, nil).Once()
	svc := NewFlagService(mockRepo, logger)

	t.Run("Given CallRepoGetAll, When calling FlagService GetAll, Then it behaves as expected", func(t *testing.T) {
		expected := []Flag{
			{Key: "1", Value: true},
			{Key: "2", Value: false},
		}
		mockRepo.On("GetAll", mock.Anything).Return(expected, nil).Once()

		result, err := svc.GetAll(context.Background())
		assert.NoError(t, err)
		assert.Equal(t, expected, result)
	})

	mockRepo.AssertExpectations(t)
}
