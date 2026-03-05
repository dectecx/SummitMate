package middleware

import (
	"context"
	"net/http"
	"strings"

	"summitmate/internal/auth"
)

type contextKey string

const UserIDKey contextKey = "user_id"

// JWTAuth returns a middleware that validates JWT tokens and injects user_id into context.
func JWTAuth(tokenMgr *auth.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if header == "" {
				http.Error(w, `{"message":"未授權"}`, http.StatusUnauthorized)
				return
			}

			parts := strings.SplitN(header, " ", 2)
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				http.Error(w, `{"message":"Token 格式錯誤"}`, http.StatusUnauthorized)
				return
			}

			claims, err := tokenMgr.ParseToken(parts[1])
			if err != nil {
				http.Error(w, `{"message":"Token 無效或已過期"}`, http.StatusUnauthorized)
				return
			}

			// Inject user_id into context
			ctx := context.WithValue(r.Context(), UserIDKey, claims.UserID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
