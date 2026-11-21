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
	cutoffs map[string]time.Time                 // userID → tokens issued at/before this instant are revoked
}

// NewMemoryTokenBlacklist returns an in-memory TokenBlacklist suitable for
// tests and local development (no external dependencies).
func NewMemoryTokenBlacklist() TokenBlacklist {
	return &memoryTokenBlacklist{
		entries: make(map[string]map[string]blacklistEntry),
		cutoffs: make(map[string]time.Time),
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

func (b *memoryTokenBlacklist) IsRevoked(ctx context.Context, userID, token string, issuedAt time.Time) (bool, error) {
	digest := tokenDigest(token)

	b.mu.RLock()
	defer b.mu.RUnlock()

	if cutoff, ok := b.cutoffs[userID]; ok && !issuedAt.Truncate(time.Second).After(cutoff) {
		return true, nil
	}

	entry, ok := b.entries[userID][digest]
	if !ok {
		return false, nil
	}
	return time.Now().Before(entry.expiresAt), nil
}

func (b *memoryTokenBlacklist) RevokeAll(ctx context.Context, userID string) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.cutoffs[userID] = time.Now().Truncate(time.Second)
	return nil
}

func (b *memoryTokenBlacklist) Close() error { return nil }
