package auth

import (
	"summitmate/internal/auth/authkeys"
	"summitmate/pkg/cache"
)

// authVerificationKey returns the cache key for email verification.
func authVerificationKey(email string) cache.Key {
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "verify",
		ID:     email,
	}
}

// AuthBlacklistKey returns the cache key for a blacklisted JWT token.
// Delegates to authkeys.BlacklistKey to share the implementation with middleware.
func AuthBlacklistKey(token string) cache.Key {
	return authkeys.BlacklistKey(token)
}
