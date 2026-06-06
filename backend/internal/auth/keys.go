package auth

import (
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

// authBlacklistKey returns the cache key for blacklisted JWT tokens.
func authBlacklistKey(token string) cache.Key {
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "blacklist",
		ID:     token,
	}
}
