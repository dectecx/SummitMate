package cache

import (
	"context"
	"sync"
	"time"
)

type blacklistEntry struct {
	expiresAt time.Time
}

type memoryTokenBlacklist struct {
	mu      sync.RWMutex
	entries map[string]map[string]blacklistEntry // userID → {digest → entry}
}

// NewMemoryTokenBlacklist returns an in-memory TokenBlacklist suitable for
// tests and local development (no external dependencies).
func NewMemoryTokenBlacklist() TokenBlacklist {
	return &memoryTokenBlacklist{
		entries: make(map[string]map[string]blacklistEntry),
	}
}

func (b *memoryTokenBlacklist) Revoke(ctx context.Context, userID, token string, expiresAt time.Time) error {
	digest := tokenDigest(token)

	b.mu.Lock()
	defer b.mu.Unlock()

	if _, ok := b.entries[userID]; !ok {
		b.entries[userID] = make(map[string]blacklistEntry)
	}
	b.entries[userID][digest] = blacklistEntry{expiresAt: expiresAt}
	return nil
}

func (b *memoryTokenBlacklist) IsRevoked(ctx context.Context, userID, token string) (bool, error) {
	digest := tokenDigest(token)

	b.mu.RLock()
	defer b.mu.RUnlock()

	userEntries, ok := b.entries[userID]
	if !ok {
		return false, nil
	}
	entry, ok := userEntries[digest]
	if !ok {
		return false, nil
	}
	return time.Now().Before(entry.expiresAt), nil
}

func (b *memoryTokenBlacklist) RevokeAll(ctx context.Context, userID string) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	delete(b.entries, userID)
	return nil
}

func (b *memoryTokenBlacklist) Close() error { return nil }
