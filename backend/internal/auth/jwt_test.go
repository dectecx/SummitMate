package auth

import (
	"testing"
	"time"

	"summitmate/internal/auth/tokens"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const testSecret = "test-secret-key-for-jwt"

// TestGenerateAndParseToken_正常流程 驗證產生 Token 後可正確解析出 Claims。
func TestGenerateAndParseToken_Success(t *testing.T) {
	manager := tokens.NewTokenManager(testSecret)

	userID := "user-123"
	email := "test@example.com"

	// 產生 Token
	token, err := manager.GenerateToken(userID, email, "access", time.Hour)
	require.NoError(t, err, "產生 Token 不應有錯誤")
	assert.NotEmpty(t, token, "Token 不應為空")

	// 解析 Token
	claims, err := manager.ParseToken(token)
	require.NoError(t, err, "解析 Token 不應有錯誤")
	assert.Equal(t, userID, claims.UserID, "user_id 應相符")
	assert.Equal(t, email, claims.Email, "email 應相符")
}

// TestParseToken_無效Token 驗證無效字串會回傳錯誤。
func TestParseToken_InvalidToken(t *testing.T) {
	manager := tokens.NewTokenManager(testSecret)

	_, err := manager.ParseToken("this.is.not.a.valid.token")
	assert.Error(t, err, "無效 Token 應回傳錯誤")
}

// TestParseToken_過期Token 驗證已過期的 Token 會被拒絕。
func TestParseToken_ExpiredToken(t *testing.T) {
	manager := tokens.NewTokenManager(testSecret)

	// 產生一個「已過期」的 Token (有效期設為 -1 小時)
	token, err := manager.GenerateToken("user-123", "test@example.com", "access", -time.Hour)
	require.NoError(t, err)

	_, err = manager.ParseToken(token)
	assert.Error(t, err, "過期 Token 應回傳錯誤")
}

// TestParseToken_錯誤密鑰 驗證用不同密鑰簽發的 Token 無法被解析。
func TestParseToken_InvalidSecret(t *testing.T) {
	manager1 := tokens.NewTokenManager("secret-one")
	manager2 := tokens.NewTokenManager("secret-two")

	// 用密鑰 1 產生 Token
	token, err := manager1.GenerateToken("user-123", "test@example.com", "access", time.Hour)
	require.NoError(t, err)

	// 用密鑰 2 嘗試解析 → 應失敗
	_, err = manager2.ParseToken(token)
	assert.Error(t, err, "用不同密鑰解析應回傳錯誤")
}
