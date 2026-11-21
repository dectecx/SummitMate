package flag

import (
	"context"
	"log/slog"
	"sync"
	"time"
)

// FlagService 定義系統旗標相關的業務邏輯介面。
type FlagService interface {
	IsEnabled(ctx context.Context, key string) bool
	SetFlag(ctx context.Context, key string, value bool, actorUserID string) error
	GetAll(ctx context.Context) ([]Flag, error)
}

type flagService struct {
	repo   FlagRepository
	logger *slog.Logger

	cache      map[string]bool
	cacheMutex sync.RWMutex
	lastFetch  time.Time
}

func NewFlagService(repo FlagRepository, logger *slog.Logger) FlagService {
	s := &flagService{
		repo:   repo,
		logger: logger.With("component", "flag"),
		cache:  make(map[string]bool),
	}
	// Initial fetch with timeout protection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = s.refreshCache(ctx)
	return s
}

func (s *flagService) refreshCache(ctx context.Context) error {
	s.cacheMutex.Lock()
	defer s.cacheMutex.Unlock()
	return s.loadFlags(ctx)
}

func (s *flagService) loadFlags(ctx context.Context) error {
	flags, err := s.repo.GetAll(ctx)
	if err != nil {
		return err
	}

	for _, f := range flags {
		s.cache[f.Key] = f.Value
	}
	s.lastFetch = time.Now()
	return nil
}

func (s *flagService) IsEnabled(ctx context.Context, key string) bool {
	s.cacheMutex.RLock()
	val, ok := s.cache[key]
	last := s.lastFetch
	s.cacheMutex.RUnlock()

	// 如果快取不存在，或超過 5 分鐘沒更新，則進行同步更新
	if !ok || time.Since(last) > 5*time.Minute {
		s.cacheMutex.Lock()
		// Double check after acquiring lock
		if !ok || time.Since(s.lastFetch) > 5*time.Minute {
			if err := s.loadFlags(ctx); err == nil {
				val = s.cache[key]
			} else {
				s.logger.Error("Failed to refresh flags cache in IsEnabled", "error", err)
			}
		}
		s.cacheMutex.Unlock()
	}

	return val
}

func (s *flagService) SetFlag(ctx context.Context, key string, value bool, actorUserID string) error {
	err := s.repo.Update(ctx, key, value, actorUserID)
	if err != nil {
		return err
	}
	// Immediately update local cache
	s.cacheMutex.Lock()
	s.cache[key] = value
	s.cacheMutex.Unlock()
	return nil
}

func (s *flagService) GetAll(ctx context.Context) ([]Flag, error) {
	return s.repo.GetAll(ctx)
}
