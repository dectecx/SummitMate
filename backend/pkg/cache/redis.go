package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type redisCache[T any] struct {
	client *redis.Client
	prefix string
}

// NewRedisCache 建立一個新的 Redis 快取實作。
func NewRedisCache[T any](client *redis.Client, prefix string) Cache[T] {
	return &redisCache[T]{
		client: client,
		prefix: prefix,
	}
}

func (r *redisCache[T]) resolveKey(key Key) string {
	if r.prefix != "" {
		return fmt.Sprintf("%s:%s", r.prefix, key.String())
	}
	return key.String()
}

func (r *redisCache[T]) Set(ctx context.Context, key Key, value T, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("redis set: marshal error: %w", err)
	}

	return r.client.Set(ctx, r.resolveKey(key), data, ttl).Err()
}

func (r *redisCache[T]) Get(ctx context.Context, key Key) (T, error) {
	var zero T
	data, err := r.client.Get(ctx, r.resolveKey(key)).Bytes()
	if err != nil {
		if err == redis.Nil {
			return zero, ErrKeyNotFound
		}
		return zero, fmt.Errorf("redis get: %w", err)
	}

	var value T
	if err := json.Unmarshal(data, &value); err != nil {
		return zero, fmt.Errorf("redis get: unmarshal error: %w", err)
	}

	return value, nil
}

func (r *redisCache[T]) Delete(ctx context.Context, key Key) error {
	return r.client.Del(ctx, r.resolveKey(key)).Err()
}

func (r *redisCache[T]) Increment(ctx context.Context, key Key, ttl time.Duration) (int64, error) {
	fullKey := r.resolveKey(key)
	val, err := r.client.Incr(ctx, fullKey).Result()
	if err != nil {
		return 0, fmt.Errorf("redis increment: %w", err)
	}

	if val == 1 && ttl > 0 {
		r.client.Expire(ctx, fullKey, ttl)
	}

	return val, nil
}
