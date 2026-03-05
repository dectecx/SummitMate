package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// ErrInvalidToken 代表 JWT Token 驗證失敗。
var ErrInvalidToken = errors.New("invalid token")

// Claims 定義 JWT Token 的自訂 Payload。
type Claims struct {
	UserID string `json:"user_id"` // 使用者 UUID
	Email  string `json:"email"`   // 使用者 Email
	jwt.RegisteredClaims
}

// TokenManager 負責 JWT Token 的簽發與驗證。
type TokenManager struct {
	secret string // HMAC 簽名密鑰
}

// NewTokenManager 建立 TokenManager 實例。
func NewTokenManager(secret string) *TokenManager {
	return &TokenManager{secret: secret}
}

// GenerateToken 為指定使用者產生一個新的 JWT Token。
// duration 為 Token 的有效時間 (例如 24*time.Hour)。
func (manager *TokenManager) GenerateToken(userID, email string, duration time.Duration) (string, error) {
	claims := Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(duration)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(manager.secret))
}

// ParseToken 解析並驗證 JWT Token 字串，回傳其中的 Claims。
// 若 Token 無效、過期或簽名不符，會回傳錯誤。
func (manager *TokenManager) ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// 確保簽名方式為 HMAC
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(manager.secret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}
