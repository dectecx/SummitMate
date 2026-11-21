package tokens

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func signWith(t *testing.T, method jwt.SigningMethod, secret string, claims Claims) string {
	t.Helper()
	signed, err := jwt.NewWithClaims(method, claims).SignedString([]byte(secret))
	require.NoError(t, err)
	return signed
}

func TestTokenManager_ParseToken_Hardening(t *testing.T) {
	const secret = "unit-test-secret-0123456789"
	manager := NewTokenManager(secret)
	validClaims := Claims{
		UserID: "u1",
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    tokenIssuer,
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	t.Run("Given a token signed by the manager, When parsing, Then it is accepted", func(t *testing.T) {
		token, err := manager.GenerateToken("u1", "a@example.com", "access", time.Hour)
		require.NoError(t, err)

		claims, err := manager.ParseToken(token)

		require.NoError(t, err)
		assert.Equal(t, "u1", claims.UserID)
		assert.Equal(t, tokenIssuer, claims.Issuer)
	})

	t.Run("Given an HS512 token with the right secret, When parsing, Then only HS256 is accepted", func(t *testing.T) {
		_, err := manager.ParseToken(signWith(t, jwt.SigningMethodHS512, secret, validClaims))

		assert.Error(t, err)
	})

	t.Run("Given a token without an expiry, When parsing, Then it is rejected", func(t *testing.T) {
		claims := validClaims
		claims.ExpiresAt = nil

		_, err := manager.ParseToken(signWith(t, jwt.SigningMethodHS256, secret, claims))

		assert.Error(t, err)
	})

	t.Run("Given a token from another issuer, When parsing, Then it is rejected", func(t *testing.T) {
		claims := validClaims
		claims.Issuer = "someone-else"

		_, err := manager.ParseToken(signWith(t, jwt.SigningMethodHS256, secret, claims))

		assert.Error(t, err)
	})

	t.Run("Given an expired token, When parsing, Then it is rejected", func(t *testing.T) {
		claims := validClaims
		claims.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-time.Minute))

		_, err := manager.ParseToken(signWith(t, jwt.SigningMethodHS256, secret, claims))

		assert.Error(t, err)
	})

	t.Run("Given the alg none attack, When parsing, Then it is rejected", func(t *testing.T) {
		none, err := jwt.NewWithClaims(jwt.SigningMethodNone, validClaims).SignedString(jwt.UnsafeAllowNoneSignatureType)
		require.NoError(t, err)

		_, err = manager.ParseToken(none)

		assert.Error(t, err)
	})
}
