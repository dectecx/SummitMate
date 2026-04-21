package flag

import (
	"context"
	"log/slog"
	"sync"
	"time"
)

type Service interface {
	IsEnabled(ctx context.Context, key string) bool
	SetFlag(ctx context.Context, key string, value bool) error
	GetAll(ctx context.Context) ([]Flag, error)
}

type service struct {
	repo   Repository
	logger *slog.Logger

	cache      map[string]bool
	cacheMutex sync.RWMutex
	lastFetch  time.Time
}

func NewService(repo Repository, logger *slog.Logger) Service {
	s := &service{
		repo:   repo,
		logger: logger.With("component", "flag"),
		cache:  make(map[string]bool),
	}
	// Initial fetch
	_ = s.refreshCache(context.Background())
	return s
}

func (s *service) refreshCache(ctx context.Context) error {
	flags, err := s.repo.GetAll(ctx)
	if err != nil {
		s.logger.Error("Failed to refresh flags cache", "error", err)
		return err
	}

	s.cacheMutex.Lock()
	defer s.cacheMutex.Unlock()

	for _, f := range flags {
		s.cache[f.Key] = f.Value
	}
	s.lastFetch = time.Now()
	return nil
}

func (s *service) IsEnabled(ctx context.Context, key string) bool {
	s.cacheMutex.RLock()
	val, ok := s.cache[key]
	last := s.lastFetch
	s.cacheMutex.RUnlock()

	// 如果快取不存在，或超過 5 分鐘沒更新，則進行同步更新
	if !ok || time.Since(last) > 5*time.Minute {
		s.cacheMutex.Lock()
		// Double check after acquiring lock
		if !ok || time.Since(s.lastFetch) > 5*time.Minute {
			if err := s.refreshCache(ctx); err == nil {
				val = s.cache[key]
			}
		}
		s.cacheMutex.Unlock()
	}

	return val
}

func (s *service) SetFlag(ctx context.Context, key string, value bool) error {
	err := s.repo.Update(ctx, key, value)
	if err != nil {
		return err
	}
	// Immediately update local cache
	s.cacheMutex.Lock()
	s.cache[key] = value
	s.cacheMutex.Unlock()
	return nil
}

func (s *service) GetAll(ctx context.Context) ([]Flag, error) {
	return s.repo.GetAll(ctx)
}
