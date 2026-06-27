package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/auth/tokens"
	"summitmate/pkg/cache"

	"github.com/stretchr/testify/assert"
)

// failingCache 模擬快取後端（如 Redis）發生非 ErrKeyNotFound 的故障，
// 用於驗證黑名單檢查的 fail-closed 行為。
type failingCache struct {
	err error
}

func (f *failingCache) Set(context.Context, cache.Key, string, time.Duration) error {
	return f.err
}

func (f *failingCache) Get(context.Context, cache.Key) (string, error) {
	return "", f.err
}

func (f *failingCache) Delete(context.Context, cache.Key) error {
	return f.err
}

func (f *failingCache) Increment(context.Context, cache.Key, time.Duration) (int64, error) {
	return 0, f.err
}

func (f *failingCache) Close() error {
	return nil
}

func TestJWTAuth_Middleware(t *testing.T) {
	secret := "super_secret_test_key_12345"
	tokenManager := tokens.NewTokenManager(secret)
	middleware := JWTAuth(tokenManager, nil)

	// 一個簡單的測試 handler，如果成功讀取到 user_id 就回傳 200 OK + UserID，否則回傳 200 + Empty
	nextHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := GetUserIDFromContext(r.Context())
		if ok {
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(userID))
		} else {
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte("anonymous"))
		}
	})

	handlerToTest := middleware(nextHandler)

	t.Run("Given public route and no token, When executing middleware, Then it passes successfully", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/public", nil)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Equal(t, "anonymous", w.Body.String())
	})

	t.Run("Given required route and no token, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		// 注入 BearerAuthScopes 模擬私有路徑
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "未授權")
	})

	t.Run("Given invalid token format, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "invalid_format_token")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 格式錯誤")
	})

	t.Run("Given empty bearer token, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer ")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "未提供認證 Token")
	})

	t.Run("Given public route and invalid token, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/public", nil)
		// 雖然是公開路徑，但如果帶了無效 Token，也應被拒絕，避免客戶端誤解
		req.Header.Set("Authorization", "Bearer wrong_token_key")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 無效或已過期")
	})

	t.Run("Given valid token, When executing middleware, Then it injects user ID into context and passes", func(t *testing.T) {
		userID := "user-12345-uuid"
		email := "test@example.com"
		tokenStr, err := tokenManager.GenerateToken(userID, email, "access", time.Hour)
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tokenStr)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Equal(t, userID, w.Body.String())
	})

	t.Run("Given refresh token, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		userID := "user-12345-uuid"
		email := "test@example.com"
		tokenStr, err := tokenManager.GenerateToken(userID, email, "refresh", time.Hour)
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tokenStr)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 類型錯誤")
	})

	t.Run("Given blacklisted token, When executing middleware, Then it returns 401 Unauthorized", func(t *testing.T) {
		memoryCache := cache.NewMemoryCache[string]()
		middlewareWithCache := JWTAuth(tokenManager, memoryCache)
		handlerToTestWithCache := middlewareWithCache(nextHandler)

		userID := "user-12345-uuid"
		email := "test@example.com"
		tokenStr, err := tokenManager.GenerateToken(userID, email, "access", time.Hour)
		assert.NoError(t, err)

		// Blacklist the token
		err = memoryCache.Set(context.Background(), authBlacklistKey(tokenStr), "1", time.Hour)
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tokenStr)
		w := httptest.NewRecorder()

		handlerToTestWithCache.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 已被註銷")
	})

	t.Run("Given non-blacklisted token with cache, When executing middleware, Then it passes successfully", func(t *testing.T) {
		memoryCache := cache.NewMemoryCache[string]()
		middlewareWithCache := JWTAuth(tokenManager, memoryCache)
		handlerToTestWithCache := middlewareWithCache(nextHandler)

		userID := "user-12345-uuid"
		email := "test@example.com"
		tokenStr, err := tokenManager.GenerateToken(userID, email, "access", time.Hour)
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tokenStr)
		w := httptest.NewRecorder()

		handlerToTestWithCache.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Equal(t, userID, w.Body.String())
	})

	t.Run("Given cache failure during blacklist check, When executing middleware, Then it fails closed with 503", func(t *testing.T) {
		brokenCache := &failingCache{err: errors.New("redis connection refused")}
		middlewareWithCache := JWTAuth(tokenManager, brokenCache)
		handlerToTestWithCache := middlewareWithCache(nextHandler)

		userID := "user-12345-uuid"
		email := "test@example.com"
		tokenStr, err := tokenManager.GenerateToken(userID, email, "access", time.Hour)
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tokenStr)
		w := httptest.NewRecorder()

		handlerToTestWithCache.ServeHTTP(w, req)

		assert.Equal(t, http.StatusServiceUnavailable, w.Code)
		assert.Contains(t, w.Body.String(), "服務暫時無法使用")
	})
}
