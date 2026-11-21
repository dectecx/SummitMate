package cache

import (
	"context"
	"time"
)

// TokenBlacklist manages revoked JWT tokens.
// Individually revoked tokens are stored per user (scored by expiry) and bulk
// revocation ("logout from all devices") stores a per-user cutoff timestamp
// that rejects every token issued at or before it.
//
// Implementations receive raw token strings and handle digest computation
// internally to keep that detail out of the call sites.
type TokenBlacklist interface {
	// Revoke adds token to userID's blacklist. The entry is considered valid
	// until expiresAt; after that point IsRevoked returns false for the same
	// token even if the record still physically exists.
	Revoke(ctx context.Context, userID, token string, expiresAt time.Time) error

	// IsRevoked reports whether the token must be rejected. A token is revoked
	// when it was individually revoked (and not yet expired), or when it was
	// issued at or before the moment RevokeAll was last called for userID.
	// issuedAt is the token's "iat" claim.
	IsRevoked(ctx context.Context, userID, token string, issuedAt time.Time) (bool, error)

	// RevokeAll invalidates every token issued to userID up to now (including
	// refresh tokens), e.g. for "logout from all devices", a password change or
	// account deletion. JWT "iat" has one-second resolution, so a token issued
	// within the same second is also treated as revoked.
	RevokeAll(ctx context.Context, userID string) error

	Close() error
}
