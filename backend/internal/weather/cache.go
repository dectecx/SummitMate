package weather

import (
	"sync"
	"time"
)

type memEntry struct {
	f       Forecast
	expires time.Time
}

type memoryCache struct {
	mu      sync.Mutex
	max     int
	ttl     time.Duration
	now     func() time.Time
	entries map[string]memEntry
}

// NewMemoryCache returns an in-memory Cache holding at most max entries, each kept for ttl.
// When full, expired entries are dropped first, then the entry closest to expiry (the oldest).
func NewMemoryCache(max int, ttl time.Duration) Cache {
	return newMemoryCache(max, ttl, time.Now)
}

func newMemoryCache(max int, ttl time.Duration, now func() time.Time) *memoryCache {
	if max < 1 {
		max = 1
	}
	return &memoryCache{max: max, ttl: ttl, now: now, entries: map[string]memEntry{}}
}

func (c *memoryCache) Get(key string) (Forecast, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	e, ok := c.entries[key]
	if !ok {
		return Forecast{}, false
	}
	if !c.now().Before(e.expires) {
		delete(c.entries, key)
		return Forecast{}, false
	}
	return e.f, true
}

func (c *memoryCache) Set(key string, f Forecast) {
	c.mu.Lock()
	defer c.mu.Unlock()
	now := c.now()
	if _, exists := c.entries[key]; !exists && len(c.entries) >= c.max {
		for k, e := range c.entries {
			if !now.Before(e.expires) {
				delete(c.entries, k)
			}
		}
		for len(c.entries) >= c.max {
			var oldest string
			var oldestAt time.Time
			for k, e := range c.entries {
				if oldest == "" || e.expires.Before(oldestAt) {
					oldest, oldestAt = k, e.expires
				}
			}
			delete(c.entries, oldest)
		}
	}
	c.entries[key] = memEntry{f: f, expires: now.Add(c.ttl)}
}
