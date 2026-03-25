package cache

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrKeyNotFound 當 Key 不存在於快取中時傳回。
	ErrKeyNotFound = errors.New("cache: key not found")
)

// Cache 定義了通用的泛型快取介面。
type Cache[T any] interface {
	// Set 存入資料，並指定存活時間 (TTL)。
	Set(ctx context.Context, key Key, value T, ttl time.Duration) error

	// Get 取得資料。若 Key 不存在，應傳回 ErrKeyNotFound。
	Get(ctx context.Context, key Key) (T, error)

	// Delete 刪除指定的資料。
	Delete(ctx context.Context, key Key) error

	// Increment 將指定的 Key 數值加一 (通常用於限流)，若 Key 不存在則初始化為 1。
	Increment(ctx context.Context, key Key, ttl time.Duration) (int64, error)
}
