package auth

import (
	"context"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
)

type ctxKey struct{}

// UserID returns the authenticated user's ID set by Middleware.
func UserID(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(ctxKey{}).(uuid.UUID)
	return id, ok
}

// BasePath is the URL prefix the API is mounted under (matches `servers` in openapi.yaml).
const BasePath = "/api/v1"

// publicPaths are the only routes reachable without a token; everything else is
// authenticated by default so a forgotten route can never be left open.
var publicPaths = map[string]bool{
	"/health":                   true,
	"/explore/mountains":        true,
	"/explore/shops":            true,
	"/auth/register":            true,
	"/auth/verify-email":        true,
	"/auth/resend-verification": true,
	"/auth/login":               true,
	"/auth/refresh":             true,
	"/auth/logout":              true,
}

// isOptionalAuth reports routes that anyone may read but that also use the caller's identity
// when a token is sent (shared sets: `mine`, owner access; group events: `my_status`, private
// message). Writes and scopes that need an identity still require a token in the handler.
func isOptionalAuth(method, path string) bool {
	if method != http.MethodGet {
		return false
	}
	if path == "/shared-sets" || path == "/group-events" {
		return true
	}
	if id, ok := strings.CutPrefix(path, "/shared-sets/"); ok {
		return id != "" && !strings.Contains(id, "/")
	}
	rest, ok := strings.CutPrefix(path, "/group-events/")
	if !ok || rest == "" {
		return false
	}
	id, sub, hasSub := strings.Cut(rest, "/")
	return id != "" && (!hasSub || sub == "comments")
}

// Middleware authenticates every request except the public paths.
func Middleware(tokens *TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			path := strings.TrimPrefix(r.URL.Path, BasePath)
			optional := isOptionalAuth(r.Method, path)
			if publicPaths[path] {
				next.ServeHTTP(w, r)
				return
			}
			h := r.Header.Get("Authorization")
			raw, ok := strings.CutPrefix(h, "Bearer ")
			if !ok || raw == "" {
				if optional && h == "" {
					next.ServeHTTP(w, r)
					return
				}
				httpx.WriteError(w, r, apperror.ErrUnauthorized)
				return
			}
			sub, err := tokens.ParseAccessToken(raw)
			if err != nil {
				httpx.WriteError(w, r, apperror.ErrUnauthorized)
				return
			}
			id, err := uuid.Parse(sub)
			if err != nil {
				httpx.WriteError(w, r, apperror.ErrUnauthorized)
				return
			}
			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxKey{}, id)))
		})
	}
}
