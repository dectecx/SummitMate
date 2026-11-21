// Package ratelimit provides a small limiter interface with an in-memory implementation.
// Swap the implementation (e.g. Redis) without touching callers.
package ratelimit

import (
	"sync"
	"time"
)

// Limiter counts events per key inside a sliding window.
type Limiter interface {
	// Allow reports whether another event for key is permitted, without recording it.
	Allow(key string) bool
	// Record registers one event for key.
	Record(key string)
	// Reset clears key.
	Reset(key string)
}

type memory struct {
	mu     sync.Mutex
	max    int
	window time.Duration
	now    func() time.Time
	events map[string][]time.Time
}

// NewMemory returns an in-memory Limiter allowing max events per window.
func NewMemory(max int, window time.Duration) Limiter {
	return &memory{max: max, window: window, now: time.Now, events: map[string][]time.Time{}}
}

func (m *memory) prune(key string) []time.Time {
	cut := m.now().Add(-m.window)
	kept := m.events[key][:0]
	for _, t := range m.events[key] {
		if t.After(cut) {
			kept = append(kept, t)
		}
	}
	if len(kept) == 0 {
		delete(m.events, key)
		return nil
	}
	m.events[key] = kept
	return kept
}

func (m *memory) Allow(key string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return len(m.prune(key)) < m.max
}

func (m *memory) Record(key string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.prune(key)
	m.events[key] = append(m.events[key], m.now())
}

func (m *memory) Reset(key string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.events, key)
}
