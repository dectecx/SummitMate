package groupevents

import (
	"context"

	"github.com/google/uuid"

	tripsync "summitmate/internal/sync"
)

// AddTripMember uses the same deterministic id as the sync service, so a removed member is revived
// and clients get the row through /sync/changes like any other membership change.
func (t pgTx) AddTripMember(ctx context.Context, tripID, userID, actor uuid.UUID) error {
	_, err := t.tx.Exec(ctx, `INSERT INTO trip_members (id, trip_id, user_id, role, created_by, updated_by)
		SELECT $1, t.id, $3, 'member', $4, $4 FROM trips t WHERE t.id = $2 AND t.deleted_at IS NULL
		ON CONFLICT (trip_id, user_id) DO UPDATE SET deleted_at = NULL, role = 'member', updated_by = $4
			WHERE trip_members.deleted_at IS NOT NULL`,
		tripsync.MemberID(tripID, userID), tripID, userID, actor)
	return err
}

func (t pgTx) RemoveTripMember(ctx context.Context, tripID, userID, actor uuid.UUID) error {
	_, err := t.tx.Exec(ctx, `UPDATE trip_members SET deleted_at = clock_timestamp(), updated_by = $3
		WHERE trip_id = $1 AND user_id = $2 AND deleted_at IS NULL AND role <> 'owner'`, tripID, userID, actor)
	return err
}
