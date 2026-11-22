package sync

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"summitmate/internal/platform/apperror"
)

// TransferOwner hands a trip to another active member. The previous owner stays on the trip as a guide.
// It is an online-only action (not a sync op): ownership changes must never be decided by last-write-wins.
func (s *Service) TransferOwner(ctx context.Context, actor, tripID, target uuid.UUID) error {
	if actor == target {
		return apperror.ErrTransferTarget
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	role, err := tripRole(ctx, tx, tripID, actor)
	if err != nil {
		return err
	}
	if role == "" {
		return apperror.ErrTripNotFound // not a member: do not reveal that the trip exists
	}
	if role != "owner" {
		return apperror.ErrNotTripOwner
	}
	targetRole, err := tripRole(ctx, tx, tripID, target)
	if err != nil {
		return err
	}
	if targetRole == "" {
		return apperror.ErrTransferTarget
	}

	if _, err := tx.Exec(ctx, `UPDATE trips SET owner_id = $2, updated_at = clock_timestamp(), updated_by = $3 WHERE id = $1`, tripID, target, actor); err != nil {
		return err
	}
	if err := setRole(ctx, tx, tripID, target, "owner", actor); err != nil {
		return err
	}
	if err := setRole(ctx, tx, tripID, actor, "guide", actor); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func setRole(ctx context.Context, tx pgx.Tx, tripID, userID uuid.UUID, role string, by uuid.UUID) error {
	_, err := tx.Exec(ctx, `UPDATE trip_members SET role = $3, updated_at = clock_timestamp(), updated_by = $4
		WHERE trip_id = $1 AND user_id = $2 AND deleted_at IS NULL`, tripID, userID, role, by)
	return err
}
