package middleware

import (
	"context"
	"net/http"
	"strings"

	"summitmate/api"
	"summitmate/internal/auth/tokens"
	"summitmate/pkg/cache"
)

// contextKey 為自訂型別，避免 context key 與其他套件衝突。
type contextKey string

// UserIDKey 是存放在 context 中的使用者 ID 鍵值。
const UserIDKey contextKey = "user_id"

func authBlacklistKey(token string) cache.Key {
	return cache.Key{
		Module: cache.ModuleAuth,
		Domain: "blacklist",
		ID:     token,
	}
}

// JWTAuth 目標：
// 1. 自動偵測 oapi-codegen 注入的 BearerAuthScopes (Context Key)
// 2. 如果不存在，表示為公開路徑，直接放行。
// 3. 如果存在，執行 Bearer Token 驗證並注入 UserID。
func JWTAuth(tokenManager *tokens.TokenManager, authCache cache.Cache[string]) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			// 檢查 oapi-codegen 注入的 Security Scopes
			// api.BearerAuthScopes 是 gen.go 中自動定義的常量 "bearerAuth.Scopes"
			_, required := request.Context().Value(api.BearerAuthScopes).([]string)

			// 取得 Authorization header
			header := request.Header.Get("Authorization")

			// 如果沒有提供 Token
			if header == "" {
				if required {
					// 必須授權的路徑，回傳 401
					http.Error(writer, `{"message":"未授權"}`, http.StatusUnauthorized)
					return
				}
				// 公開端點且未提供 Token，直接放行
				next.ServeHTTP(writer, request)
				return
			}

			// --- 以下為驗證邏輯 (當有提供 Token 時) ---

			// 解析 "Bearer <token>" 格式
			parts := strings.SplitN(header, " ", 2)
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				if required {
					http.Error(writer, `{"message":"Token 格式錯誤"}`, http.StatusUnauthorized)
					return
				}
				next.ServeHTTP(writer, request)
				return
			}

			tokenStr := strings.TrimSpace(parts[1])
			if tokenStr == "" {
				if required {
					http.Error(writer, `{"message":"未提供認證 Token"}`, http.StatusUnauthorized)
					return
				}
				next.ServeHTTP(writer, request)
				return
			}

			// 驗證 Token
			claims, err := tokenManager.ParseToken(tokenStr)
			if err != nil {
				// 如果有提供 Token 但無效，一律回傳 401，避免客戶端誤解
				http.Error(writer, `{"message":"Token 無效或已過期"}`, http.StatusUnauthorized)
				return
			}

			// 檢查 Token 是否在黑名單中
			if authCache != nil {
				_, err := authCache.Get(request.Context(), authBlacklistKey(tokenStr))
				if err == nil {
					// 找到 Key 代表已被註銷/列入黑名單
					http.Error(writer, `{"message":"Token 已被註銷"}`, http.StatusUnauthorized)
					return
				}
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
