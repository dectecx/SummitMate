package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMiddlewareIsDenyByDefault(t *testing.T) {
	tm := NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	var gotUser uuid.UUID
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotUser, _ = UserID(r.Context())
		w.WriteHeader(http.StatusNoContent)
	})
	h := Middleware(tm)(next)
	uid := uuid.New()
	tok, err := tm.NewAccessToken(uid.String())
	require.NoError(t, err)

	call := func(path, header string) int {
		req := httptest.NewRequest(http.MethodGet, BasePath+path, nil)
		if header != "" {
			req.Header.Set("Authorization", header)
		}
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec.Code
	}

	for _, p := range []string{"/health", "/auth/login", "/auth/register", "/auth/refresh", "/auth/verify-email", "/explore/mountains"} {
		assert.Equal(t, http.StatusNoContent, call(p, ""), "public: %s", p)
	}
	for _, p := range []string{"/auth/me", "/sync/changes", "/sync/push", "/users/search", "/anything/new", "/explore/mountains/x", "/explore", "/weather/forecast"} {
		assert.Equal(t, http.StatusUnauthorized, call(p, ""), "no token: %s", p)
		assert.Equal(t, http.StatusUnauthorized, call(p, "Bearer garbage"), "bad token: %s", p)
		assert.Equal(t, http.StatusUnauthorized, call(p, "Basic "+tok), "wrong scheme: %s", p)
	}
	assert.Equal(t, http.StatusNoContent, call("/sync/changes", "Bearer "+tok))
	assert.Equal(t, uid, gotUser)
}
