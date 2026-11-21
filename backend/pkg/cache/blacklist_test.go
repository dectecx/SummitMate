package cache

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMemoryTokenBlacklist_RevokeAll(t *testing.T) {
	ctx := context.Background()
	user := "user-1"
	expires := time.Now().Add(time.Hour)

	t.Run("Given tokens issued before RevokeAll, When checking them, Then they are revoked", func(t *testing.T) {
		bl := NewMemoryTokenBlacklist()
		issued := time.Now().Add(-time.Minute)

		require.NoError(t, bl.RevokeAll(ctx, user))

		revoked, err := bl.IsRevoked(ctx, user, "any-token", issued)
		require.NoError(t, err)
		assert.True(t, revoked)
	})

	t.Run("Given tokens issued after RevokeAll, When checking them, Then they are accepted", func(t *testing.T) {
		bl := NewMemoryTokenBlacklist()
		require.NoError(t, bl.RevokeAll(ctx, user))

		revoked, err := bl.IsRevoked(ctx, user, "new-token", time.Now().Add(2*time.Second))
		require.NoError(t, err)
		assert.False(t, revoked)
	})

	t.Run("Given a revoked token, When RevokeAll is called, Then it stays revoked", func(t *testing.T) {
		bl := NewMemoryTokenBlacklist()
		later := time.Now().Add(10 * time.Second)
		require.NoError(t, bl.Revoke(ctx, user, "revoked-token", expires))

		require.NoError(t, bl.RevokeAll(ctx, user))

		revoked, err := bl.IsRevoked(ctx, user, "revoked-token", later)
		require.NoError(t, err)
		assert.True(t, revoked, "RevokeAll must never un-revoke a token")
	})

	t.Run("Given another user, When RevokeAll is called for the first user, Then the other is unaffected", func(t *testing.T) {
		bl := NewMemoryTokenBlacklist()
		require.NoError(t, bl.RevokeAll(ctx, user))

		revoked, err := bl.IsRevoked(ctx, "user-2", "token", time.Now().Add(-time.Minute))
		require.NoError(t, err)
		assert.False(t, revoked)
	})
}
