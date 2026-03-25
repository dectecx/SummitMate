package middleware

import (
	"context"
	"net/http"
	"strings"

	"summitmate/api"
	"summitmate/internal/auth"
)

// contextKey 為自訂型別，避免 context key 與其他套件衝突。
type contextKey string

// UserIDKey 是存放在 context 中的使用者 ID 鍵值。
const UserIDKey contextKey = "user_id"

// JWTAuth 目標：
// 1. 自動偵測 oapi-codegen 注入的 BearerAuthScopes (Context Key)
// 2. 如果不存在，表示為公開路徑，直接放行。
// 3. 如果存在，執行 Bearer Token 驗證並注入 UserID。
func JWTAuth(tokenManager *auth.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			// 檢查 oapi-codegen 注入的 Security Scopes
			// api.BearerAuthScopes 是 gen.go 中自動定義的常量 "bearerAuth.Scopes"
			_, required := request.Context().Value(api.BearerAuthScopes).([]string)

			if !required {
				// 公開端點，直接放行
				next.ServeHTTP(writer, request)
				return
			}

			// --- 以下為驗證邏輯 ---

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

// GetUserIDFromContext 從 context 取得 JWT middleware 注入的 user_id。
func GetUserIDFromContext(ctx context.Context) (string, bool) {
	userID, ok := ctx.Value(UserIDKey).(string)
	return userID, ok
}
