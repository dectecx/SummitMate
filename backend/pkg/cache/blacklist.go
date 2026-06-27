package cache

import (
	"context"
	"time"
)

// TokenBlacklist manages revoked JWT tokens in a per-user sorted set.
// Each user's revoked tokens are stored under a single key, scored by their
// expiry unix timestamp. This design supports O(log N) lookup and enables
// bulk revocation ("logout from all devices") with a single DEL.
//
// Implementations receive raw token strings and handle digest computation
// internally to keep that detail out of the call sites.
type TokenBlacklist interface {
	// Revoke adds token to userID's blacklist. The entry is considered valid
	// until expiresAt; after that point IsRevoked returns false for the same
	// token even if the record still physically exists.
	Revoke(ctx context.Context, userID, token string, expiresAt time.Time) error

	// IsRevoked reports whether token is present in userID's blacklist and
	// has not yet passed its expiry time.
	IsRevoked(ctx context.Context, userID, token string) (bool, error)

	// RevokeAll invalidates every token for userID by dropping the whole
	// blacklist key. Intended for "logout from all devices".
	RevokeAll(ctx context.Context, userID string) error

	Close() error
}
