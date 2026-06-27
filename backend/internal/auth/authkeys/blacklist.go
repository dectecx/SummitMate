package authkeys

import (
	"crypto/sha256"
	"fmt"

	"summitmate/pkg/cache"
)

// BlacklistKey returns the cache key for a blacklisted JWT token.
// The token is hashed with SHA-256 to avoid exposing sensitive credentials in
// cache logs or monitoring systems.
func BlacklistKey(token string) cache.Key {
	digest := fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "blacklist",
		ID:     digest,
	}
}
