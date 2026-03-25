package cache

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"sync"
	"time"
)

type cacheItem[T any] struct {
	value     T
	expiresAt int64 // UnixNano
}

type memoryCache[T any] struct {
	items sync.Map
	mu    sync.Mutex // 用於 Increment 的原子操作
}

// NewMemoryCache 建立一個新的記憶體快取實作。
func NewMemoryCache[T any]() Cache[T] {
	c := &memoryCache[T]{}
	go c.startJanitor(time.Minute)
	return c
}

func (c *memoryCache[T]) Set(ctx context.Context, key Key, value T, ttl time.Duration) error {
	var expires int64
	if ttl > 0 {
		expires = time.Now().Add(ttl).UnixNano()
	}

	c.items.Store(key.String(), cacheItem[T]{
		value:     value,
		expiresAt: expires,
	})
	return nil
}

func (c *memoryCache[T]) Get(ctx context.Context, key Key) (T, error) {
	var zero T
	val, ok := c.items.Load(key.String())
	if !ok {
		return zero, ErrKeyNotFound
	}

	item := val.(cacheItem[T])
	if item.expiresAt > 0 && time.Now().UnixNano() > item.expiresAt {
		c.items.Delete(key.String())
		return zero, ErrKeyNotFound
	}

	return item.value, nil
}

func (c *memoryCache[T]) Delete(ctx context.Context, key Key) error {
	c.items.Delete(key.String())
	return nil
}

func (c *memoryCache[T]) Increment(ctx context.Context, key Key, ttl time.Duration) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	k := key.String()
	var newValue int64 = 1
	var expires int64

	if val, ok := c.items.Load(k); ok {
		item := val.(cacheItem[T])
		// 檢查是否過期
		if item.expiresAt > 0 && time.Now().UnixNano() > item.expiresAt {
			// 已過期，重新開始
		} else {
			// 嘗試轉為 int64。這裡需要一點技巧，因為 T 可能是任何型別。
			// 模仿 Redis 行為：如果原本是字串且內含數字，也應允許累加。
			var current int64
			var parseErr error

			switch v := any(item.value).(type) {
			case int64:
				current = v
			case string:
				current, parseErr = strconv.ParseInt(v, 10, 64)
			default:
				parseErr = errors.New("not a supported type")
			}

			if parseErr == nil {
				newValue = current + 1
				expires = item.expiresAt
			} else {
				return 0, errors.New("cache: value is not an integer")
			}
		}
	}

	if expires == 0 && ttl > 0 {
		expires = time.Now().Add(ttl).UnixNano()
	}

	// 根據 T 的型別進行安全轉換
	var zero T
	var valToStore T
	switch any(zero).(type) {
	case int64:
		valToStore = any(newValue).(T)
	case string:
		valToStore = any(fmt.Sprintf("%d", newValue)).(T)
	default:
		// 嘗試直接斷言，若不行則回傳錯誤
		if v, ok := any(newValue).(T); ok {
			valToStore = v
		} else {
			return 0, fmt.Errorf("cache: increment not supported for type %T", zero)
		}
	}

	c.items.Store(k, cacheItem[T]{
		value:     valToStore,
		expiresAt: expires,
	})

	return newValue, nil
}

func (c *memoryCache[T]) startJanitor(interval time.Duration) {
	ticker := time.NewTicker(interval)
	for range ticker.C {
		now := time.Now().UnixNano()
		c.items.Range(func(key, value any) bool {
			item := value.(cacheItem[T])
			if item.expiresAt > 0 && now > item.expiresAt {
				c.items.Delete(key)
			}
			return true
		})
	}
}
