package cache

import (
	"context"
	"fmt"
	"strconv"

	"github.com/redis/go-redis/v9"
)

// Provider 定義了快取實作的提供者型別。
type Provider string

const (
	ProviderMemory Provider = "memory"
	ProviderRedis  Provider = "redis"
)

// Config 定義了快取的配置。
type Config struct {
	Type          Provider
	RedisAddr     string
	RedisPassword string
	RedisDB       string
}

// NewCache 根據配置建立適當的快取實作。
func NewCache[T any](cfg Config) (Cache[T], error) {
	switch cfg.Type {
	case ProviderRedis:
		db, err := strconv.Atoi(cfg.RedisDB)
		if err != nil {
			return nil, fmt.Errorf("invalid redis db: %w", err)
		}

		client := redis.NewClient(&redis.Options{
			Addr:     cfg.RedisAddr,
			Password: cfg.RedisPassword,
			DB:       db,
		})

		// 檢查 Redis 連線
		if err := client.Ping(context.Background()).Err(); err != nil {
			return nil, fmt.Errorf("redis connection failed: %w", err)
		}

		return NewRedisCache[T](client, ""), nil
	case ProviderMemory:
		fallthrough
	default:
		return NewMemoryCache[T](), nil
	}
}
