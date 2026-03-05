package auth

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestHashPassword_成功產生雜湊 驗證雜湊值不為空且不等於原始密碼。
func TestHashPassword_Success(t *testing.T) {
	hash, err := HashPassword("mySecurePass123")
	require.NoError(t, err, "不應產生錯誤")
	assert.NotEmpty(t, hash, "雜湊值不應為空")
	assert.NotEqual(t, "mySecurePass123", hash, "雜湊值不應等於原始密碼")
}

// TestCheckPasswordHash_正確密碼 驗證正確密碼可通過比對。
func TestCheckPasswordHash_Valid(t *testing.T) {
	password := "testPass!@#456"
	hash, err := HashPassword(password)
	require.NoError(t, err)

	assert.True(t, CheckPasswordHash(password, hash), "正確密碼應比對成功")
}

// TestCheckPasswordHash_錯誤密碼 驗證錯誤密碼會被拒絕。
func TestCheckPasswordHash_Invalid(t *testing.T) {
	hash, err := HashPassword("correctPassword")
	require.NoError(t, err)

	assert.False(t, CheckPasswordHash("wrongPassword", hash), "錯誤密碼應比對失敗")
}

// TestHashPassword_相同輸入產生不同雜湊 驗證 bcrypt 的 salt 機制。
func TestHashPassword_DifferentHashes(t *testing.T) {
	hash1, err := HashPassword("samePassword")
	require.NoError(t, err)

	hash2, err := HashPassword("samePassword")
	require.NoError(t, err)

	assert.NotEqual(t, hash1, hash2, "bcrypt 每次應產生不同雜湊 (因為有 salt)")
}
