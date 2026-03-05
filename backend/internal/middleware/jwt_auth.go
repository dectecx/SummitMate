package middleware

import (
	"context"
	"net/http"
	"strings"

	"summitmate/internal/auth"
)

// contextKey 為自訂型別，避免 context key 與其他套件衝突。
type contextKey string

// UserIDKey 是存放在 context 中的使用者 ID 鍵值。
const UserIDKey contextKey = "user_id"

// JWTAuth 回傳一個 HTTP middleware，負責：
//  1. 從 Authorization header 取得 Bearer Token
//  2. 驗證 Token 有效性
//  3. 將 user_id 注入到 request context 中
//
// 若驗證失敗，直接回傳 401 Unauthorized。
func JWTAuth(tokenManager *auth.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			// 取得 Authorization header
			header := request.Header.Get("Authorization")
			if header == "" {
				http.Error(writer, `{"message":"未授權"}`, http.StatusUnauthorized)
				return
			}

			// 解析 "Bearer <token>" 格式
			parts := strings.SplitN(header, " ", 2)
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				http.Error(writer, `{"message":"Token 格式錯誤"}`, http.StatusUnauthorized)
				return
			}

			// 驗證 Token
			claims, err := tokenManager.ParseToken(parts[1])
			if err != nil {
				http.Error(writer, `{"message":"Token 無效或已過期"}`, http.StatusUnauthorized)
				return
			}

			// 將 user_id 注入 context，供下游 handler 使用
			ctx := context.WithValue(request.Context(), UserIDKey, claims.UserID)
			next.ServeHTTP(writer, request.WithContext(ctx))
		})
	}
}
