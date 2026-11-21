package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// incrementScript 以單一 Lua script 讓 INCR + PEXPIRE 原子化執行，
// 避免 INCR 成功但 EXPIRE 失敗（或兩指令之間崩潰）導致計數 key 永久殘留。
// KEYS[1]=key、ARGV[1]=ttl(毫秒，<=0 表示不設定過期)。
var incrementScript = redis.NewScript(`
local current = redis.call('INCR', KEYS[1])
if current == 1 then
    local ttl = tonumber(ARGV[1])
    if ttl and ttl > 0 then
        redis.call('PEXPIRE', KEYS[1], ttl)
    end
end
return current
`)

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
	val, err := incrementScript.Run(ctx, r.client, []string{fullKey}, ttl.Milliseconds()).Int64()
	if err != nil {
		return 0, fmt.Errorf("redis increment: %w", err)
	}

	return val, nil
}

func (r *redisCache[T]) Close() error {
	return r.client.Close()
}
