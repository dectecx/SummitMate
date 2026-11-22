package sync

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// insertChecks runs the relational checks that new trip_messages, poll_options and poll_votes
// rows need. done is true when res must be returned instead of inserting.
func insertChecks(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, op Op, tripID uuid.UUID, role string, vals map[string]any) (res Result, done bool, err error) {
	switch e.access {
	case accessAuthor:
		parent, ok := vals["parent_id"].(uuid.UUID)
		if !ok {
			return Result{}, false, nil
		}
		var parentTrip uuid.UUID
		var grand *uuid.UUID
		err := tx.QueryRow(ctx, `SELECT trip_id, parent_id FROM trip_messages WHERE id = $1`, parent).Scan(&parentTrip, &grand)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && parentTrip != tripID) {
			res, _ = invalid("parent_id does not exist in this trip")
			return res, true, nil
		}
		if err != nil {
			return Result{}, false, err
		}
		if grand != nil {
			res, _ = invalid("只能回覆最上層的留言")
			return res, true, nil
		}
	case accessOption:
		poll, err := loadPoll(ctx, tx, vals["poll_id"].(uuid.UUID))
		if err != nil {
			return Result{}, false, err
		}
		if !poll.live || poll.tripID != tripID {
			res, _ = invalid("poll_id does not exist in this trip")
			return res, true, nil
		}
		if !isEditor(role) && !(poll.allowAddOption && poll.status == "open") {
			res, _ = forbidden("這個投票不開放成員新增選項")
			return res, true, nil
		}
	case accessVote:
		optionID := vals["option_id"].(uuid.UUID)
		if op.EntityID != VoteID(optionID, userID) {
			res, _ = invalid("poll_votes id must be uuidv5(option_id:user_id)")
			return res, true, nil
		}
		msg, err := checkVoteTarget(ctx, tx, vals["poll_id"].(uuid.UUID), optionID, tripID)
		if err != nil {
			return Result{}, false, err
		}
		if msg != "" {
			res, _ = invalid(msg)
			return res, true, nil
		}
	}
	return Result{}, false, nil
}

type pollInfo struct {
	live           bool
	tripID         uuid.UUID
	status         string
	allowAddOption bool
}

func loadPoll(ctx context.Context, tx pgx.Tx, id uuid.UUID) (pollInfo, error) {
	var p pollInfo
	var deletedAt *time.Time
	err := tx.QueryRow(ctx, `SELECT trip_id, status, allow_add_option, deleted_at FROM polls WHERE id = $1`, id).
		Scan(&p.tripID, &p.status, &p.allowAddOption, &deletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return pollInfo{}, nil
	}
	p.live = err == nil && deletedAt == nil
	return p, err
}

// checkVoteTarget returns a message when the option or poll is missing, deleted or in another trip.
func checkVoteTarget(ctx context.Context, tx pgx.Tx, pollID, optionID, tripID uuid.UUID) (string, error) {
	poll, err := loadPoll(ctx, tx, pollID)
	if err != nil {
		return "", err
	}
	if !poll.live || poll.tripID != tripID {
		return "poll_id does not exist in this trip", nil
	}
	var optPoll, optTrip uuid.UUID
	var deletedAt *time.Time
	err = tx.QueryRow(ctx, `SELECT poll_id, trip_id, deleted_at FROM poll_options WHERE id = $1`, optionID).Scan(&optPoll, &optTrip, &deletedAt)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && (deletedAt != nil || optPoll != pollID || optTrip != tripID)) {
		return "option_id does not belong to this poll", nil
	}
	return "", err
}

// voteTargetProblem re-checks the option and poll of a stored vote before it is revived.
func voteTargetProblem(ctx context.Context, tx pgx.Tx, voteID uuid.UUID) (string, error) {
	var pollID, optionID, tripID uuid.UUID
	if err := tx.QueryRow(ctx, `SELECT poll_id, option_id, trip_id FROM poll_votes WHERE id = $1`, voteID).Scan(&pollID, &optionID, &tripID); err != nil {
		return "", err
	}
	return checkVoteTarget(ctx, tx, pollID, optionID, tripID)
}
