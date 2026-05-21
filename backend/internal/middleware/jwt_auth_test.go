package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"summitmate/api"
	"summitmate/internal/auth/tokens"

	"github.com/stretchr/testify/assert"
)

func TestJWTAuth_Middleware(t *testing.T) {
	secret := "super_secret_test_key_12345"
	tokenManager := tokens.NewTokenManager(secret)
	middleware := JWTAuth(tokenManager)

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

	t.Run("PublicRoute_NoToken_Bypass", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/public", nil)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Equal(t, "anonymous", w.Body.String())
	})

	t.Run("RequiredRoute_NoToken_Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		// 注入 BearerAuthScopes 模擬私有路徑
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "未授權")
	})

	t.Run("RequiredRoute_InvalidTokenFormat_Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "invalid_format_token")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 格式錯誤")
	})

	t.Run("RequiredRoute_EmptyBearerToken_Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/private", nil)
		ctx := context.WithValue(req.Context(), api.BearerAuthScopes, []string{})
		req = req.WithContext(ctx)
		req.Header.Set("Authorization", "Bearer ")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "未提供認證 Token")
	})

	t.Run("PublicRoute_InvalidToken_Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/public", nil)
		// 雖然是公開路徑，但如果帶了無效 Token，也應被拒絕，避免客戶端誤解
		req.Header.Set("Authorization", "Bearer wrong_token_key")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Token 無效或已過期")
	})

	t.Run("Success_InjectUserID", func(t *testing.T) {
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
}
