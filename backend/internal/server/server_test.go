package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/auth"
	"summitmate/internal/sync"
)

func newTestRouter() http.Handler {
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	// Services are nil on purpose: these tests never get past authentication or validation.
	return NewRouter(Options{
		Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Tokens: tm,
		MaxBodyBytes: 1 << 10, RequestTimeout: time.Second,
	})
}

func do(h http.Handler, method, path, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestHealthIsPublic(t *testing.T) {
	rec := do(newTestRouter(), http.MethodGet, "/api/v1/health", "")
	assert.Equal(t, http.StatusOK, rec.Code)
	assert.JSONEq(t, `{"status":"ok"}`, rec.Body.String())
}

func TestProtectedRoutesRequireAuth(t *testing.T) {
	h := newTestRouter()
	for _, tc := range []struct{ method, path string }{
		{http.MethodGet, "/api/v1/auth/me"},
		{http.MethodGet, "/api/v1/sync/changes"},
		{http.MethodPost, "/api/v1/sync/push"},
		{http.MethodGet, "/api/v1/users/search?email=a@b.co"},
		{http.MethodPost, "/api/v1/auth/change-password"},
	} {
		rec := do(h, tc.method, tc.path, "{}")
		assert.Equal(t, http.StatusUnauthorized, rec.Code, tc.path)
		var body map[string]any
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
		assert.Equal(t, "unauthorized", body["code"])
	}
}

func TestMalformedAndOversizedBodiesAreRejected(t *testing.T) {
	h := newTestRouter()
	rec := do(h, http.MethodPost, "/api/v1/auth/login", "{not json")
	assert.Equal(t, http.StatusBadRequest, rec.Code)

	rec = do(h, http.MethodPost, "/api/v1/auth/login", `{"email":"a@b.co","password":"`+strings.Repeat("x", 2000)+`"}`)
	assert.Equal(t, http.StatusRequestEntityTooLarge, rec.Code)
}

func TestInvalidQueryParamIsBadRequest(t *testing.T) {
	// Authenticate with a real token, then send a bad `since`.
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	tok, err := tm.NewAccessToken("2d1d0a1e-5c0f-4a5e-8a43-0c0f0b1a1111")
	require.NoError(t, err)
	h := NewRouter(Options{Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Tokens: tm, MaxBodyBytes: 1 << 10, RequestTimeout: time.Second})
	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/changes?since=yesterday", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusBadRequest, rec.Code)
}
