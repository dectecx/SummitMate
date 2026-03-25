package cache

import (
	"context"
	"errors"
	"sync"
	"time"
)

type cacheItem[T any] struct {
	value     T
	expiresAt int64 // UnixNano
}

type memoryCache[T any] struct {
	items sync.Map
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
	// 這裡的實作稍微複雜一點，因為 sync.Map 不適合直接做原子累加。
	// 在記憶體實作中，我們通常針對 int64 進行特殊處理。
	// 由於這是泛型快取，我們假設呼叫者知道 T 在此場景下應與 int64 相容。
	// 但為了簡化設計，若 T 不是 int64，這裡可能會報錯或行為異常。

	// 注意：目前的泛型介面 Cache[T] 限制了 T 的型別。
	// 如果我們需要純 Counter，或許應該獨立出來。
	// 但為了符合 Generic 要求，我們嘗試在此處處理。

	// 簡化做法：在通用 Cache 中，Increment 可能需要內部鎖定。
	// 這裡先實作一個基礎版本。

	// FIXME: 泛型基礎下的 Increment 在 Go 中較難完美達成，除非 T 是數字型別。
	// 此處暫時僅作示意，核心驗證機制暫不需要此功能。
	return 0, errors.New("increment not implemented for generic memory cache")
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
