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

// loginRateKey returns the cache key for counting login attempts per email.
func loginRateKey(email string) cache.Key {
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "rate:login",
		ID:     email,
	}
}

// resendRateKey returns the cache key for counting resend verification attempts per email.
func resendRateKey(email string) cache.Key {
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "rate:resend",
		ID:     email,
	}
}
