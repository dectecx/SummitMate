package sync

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/platform/apperror"
)

func roleOf(t *testing.T, s *Service, trip, user uuid.UUID) string {
	t.Helper()
	var role string
	require.NoError(t, s.pool.QueryRow(context.Background(), `SELECT role FROM trip_members WHERE trip_id = $1 AND user_id = $2`, trip, user).Scan(&role))
	return role
}

func TestTransferOwner(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	ctx := context.Background()
	owner, member, guide, stranger := newUser(t, pool, "o"), newUser(t, pool, "m"), newUser(t, pool, "g"), newUser(t, pool, "x")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, member, "member")
	addMember(t, s, owner, trip, guide, "guide")

	// Only the owner, only to another member of the trip.
	assert.ErrorIs(t, s.TransferOwner(ctx, guide, trip, member), apperror.ErrNotTripOwner)
	assert.ErrorIs(t, s.TransferOwner(ctx, stranger, trip, member), apperror.ErrTripNotFound)
	assert.ErrorIs(t, s.TransferOwner(ctx, owner, trip, stranger), apperror.ErrTransferTarget)
	assert.ErrorIs(t, s.TransferOwner(ctx, owner, trip, owner), apperror.ErrTransferTarget)
	assert.Equal(t, "owner", roleOf(t, s, trip, owner), "nothing changed after refusals")

	before := pullAll(t, s, member, nil).ServerTime
	require.NoError(t, s.TransferOwner(ctx, owner, trip, member))
	assert.Equal(t, "owner", roleOf(t, s, trip, member))
	assert.Equal(t, "guide", roleOf(t, s, trip, owner), "the previous owner stays as a guide")
	var ownerID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `SELECT owner_id FROM trips WHERE id = $1`, trip).Scan(&ownerID))
	assert.Equal(t, member, ownerID)

	// Members receive the change through the normal pull.
	ch := pullAll(t, s, guide, &before)
	assert.Len(t, ch.Rows["trips"], 1)
	assert.Len(t, ch.Rows["trip_members"], 2)

	// The old owner can no longer transfer or delete the trip; the new one can.
	assert.ErrorIs(t, s.TransferOwner(ctx, owner, trip, member), apperror.ErrNotTripOwner)
	assert.Equal(t, StatusForbidden, mustPush(t, s, owner, del("trips", trip))[0].Status)
	assert.Equal(t, StatusApplied, mustPush(t, s, member, del("trips", trip))[0].Status)
}
