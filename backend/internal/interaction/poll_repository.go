package interaction

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

type PollRepository interface {
	CreatePoll(ctx context.Context, poll *Poll) error
	GetPollByID(ctx context.Context, pollID string) (*Poll, error)
	ListTripPolls(ctx context.Context, tripID string, page int, limit int) ([]*Poll, int, bool, error)
	DeletePoll(ctx context.Context, pollID string) error

	AddPollOption(ctx context.Context, option *PollOption) error
	GetPollOption(ctx context.Context, optionID string) (*PollOption, error)

	VoteOption(ctx context.Context, pollID, optionID, userID string, allowMultiple bool) error
}

type pollRepository struct {
	db database.DB
}

func NewPollRepository(db database.DB) PollRepository {
	return &pollRepository{db: db}
}

func (r *pollRepository) CreatePoll(ctx context.Context, poll *Poll) error {
	query := `
		INSERT INTO polls (
			trip_id, title, description, deadline,
			is_allow_add_option, max_option_limit, allow_multiple_votes,
			result_display_type, status, created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
		) RETURNING id, created_at, updated_at
	`
	var id string
	var createdAt, updatedAt time.Time

	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		poll.TripID, poll.Title, poll.Description, poll.Deadline,
		poll.IsAllowAddOption, poll.MaxOptionLimit, poll.AllowMultipleVotes,
		poll.ResultDisplayType, poll.Status, poll.CreatedBy, poll.UpdatedBy,
	).Scan(&id, &createdAt, &updatedAt)
	if err != nil {
		return fmt.Errorf("create poll for trip %s: %w", poll.TripID, err)
	}

	poll.ID = id
	poll.CreatedAt = createdAt
	poll.UpdatedAt = updatedAt
	poll.Options = []*PollOption{}
	return nil
}

func (r *pollRepository) loadPollOptions(ctx context.Context, pollID string) ([]*PollOption, error) {
	// First fetch all options
	optQuery := `SELECT id, poll_id, text, created_at, created_by, updated_at, updated_by FROM poll_options WHERE poll_id = $1 ORDER BY created_at ASC`
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, optQuery, pollID)
	if err != nil {
		return nil, fmt.Errorf("query poll options for poll %s: %w", pollID, err)
	}
	defer rows.Close()

	var options []*PollOption
	optMap := make(map[string]*PollOption)
	for rows.Next() {
		var opt PollOption
		if err := rows.Scan(&opt.ID, &opt.PollID, &opt.Text, &opt.CreatedAt, &opt.CreatedBy, &opt.UpdatedAt, &opt.UpdatedBy); err != nil {
			return nil, fmt.Errorf("scan poll option row: %w", err)
		}
		opt.Voters = []string{}
		options = append(options, &opt)
		optMap[opt.ID] = &opt
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate poll option rows: %w", err)
	}

	// Then fetch votes for those options
	if len(options) > 0 {
		voteQuery := `SELECT option_id, user_id FROM poll_votes WHERE poll_id = $1`
		vRows, err := db.Query(ctx, voteQuery, pollID)
		if err == nil {
			defer vRows.Close()
			for vRows.Next() {
				var optID, userID string
				if err := vRows.Scan(&optID, &userID); err == nil {
					if opt, ok := optMap[optID]; ok {
						opt.Voters = append(opt.Voters, userID)
						opt.VoteCount++
					}
				}
			}
		}
	}

	return options, nil
}

func (r *pollRepository) GetPollByID(ctx context.Context, pollID string) (*Poll, error) {
	query := `
		SELECT id, trip_id, title, description, deadline,
		is_allow_add_option, max_option_limit, allow_multiple_votes,
		result_display_type, status, created_at, created_by, updated_at, updated_by
		FROM polls WHERE id = $1
	`
	var p Poll
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, pollID).Scan(
		&p.ID, &p.TripID, &p.Title, &p.Description, &p.Deadline,
		&p.IsAllowAddOption, &p.MaxOptionLimit, &p.AllowMultipleVotes,
		&p.ResultDisplayType, &p.Status, &p.CreatedAt, &p.CreatedBy, &p.UpdatedAt, &p.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get poll %s: %w", pollID, err)
	}

	options, err := r.loadPollOptions(ctx, p.ID)
	if err != nil {
		return nil, fmt.Errorf("load options for poll %s: %w", p.ID, err)
	}
	p.Options = options

	return &p, nil
}

func (r *pollRepository) ListTripPolls(ctx context.Context, tripID string, page int, limit int) ([]*Poll, int, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}

	db := database.GetQuerier(ctx, r.db)
	var total int
	if err := db.QueryRow(ctx, `SELECT COUNT(*) FROM polls WHERE trip_id = $1`, tripID).Scan(&total); err != nil {
		return nil, 0, false, fmt.Errorf("count polls for trip %s: %w", tripID, err)
	}

	query := `
		SELECT id, trip_id, title, description, deadline,
		is_allow_add_option, max_option_limit, allow_multiple_votes,
		result_display_type, status, created_at, created_by, updated_at, updated_by
		FROM polls WHERE trip_id = $1
		ORDER BY created_at DESC, id DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := db.Query(ctx, query, tripID, limit, (page-1)*limit)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query polls for trip %s: %w", tripID, err)
	}
	defer rows.Close()

	var polls []*Poll
	for rows.Next() {
		var p Poll
		if err := rows.Scan(
			&p.ID, &p.TripID, &p.Title, &p.Description, &p.Deadline,
			&p.IsAllowAddOption, &p.MaxOptionLimit, &p.AllowMultipleVotes,
			&p.ResultDisplayType, &p.Status, &p.CreatedAt, &p.CreatedBy, &p.UpdatedAt, &p.UpdatedBy,
		); err != nil {
			return nil, 0, false, fmt.Errorf("scan poll row: %w", err)
		}
		polls = append(polls, &p)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, false, fmt.Errorf("iterate poll rows: %w", err)
	}

	for _, p := range polls {
		options, err := r.loadPollOptions(ctx, p.ID)
		if err == nil {
			p.Options = options
		} else {
			p.Options = []*PollOption{}
		}
	}

	return polls, total, page*limit < total, nil
}

func (r *pollRepository) DeletePoll(ctx context.Context, pollID string) error {
	query := `DELETE FROM polls WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	cmd, err := db.Exec(ctx, query, pollID)
	if err != nil {
		return fmt.Errorf("delete poll %s: %w", pollID, err)
	}
	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("poll %s not found", pollID)
	}
	return nil
}

func (r *pollRepository) AddPollOption(ctx context.Context, option *PollOption) error {
	query := `
		INSERT INTO poll_options (poll_id, text, created_by, updated_by)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, option.PollID, option.Text, option.CreatedBy, option.UpdatedBy).Scan(&option.ID, &option.CreatedAt, &option.UpdatedAt)
	if err != nil {
		return fmt.Errorf("add poll option to poll %s: %w", option.PollID, err)
	}
	option.Voters = []string{}
	option.VoteCount = 0
	return nil
}

func (r *pollRepository) GetPollOption(ctx context.Context, optionID string) (*PollOption, error) {
	query := `SELECT id, poll_id, text, created_at, created_by, updated_at, updated_by FROM poll_options WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	var opt PollOption
	err := db.QueryRow(ctx, query, optionID).Scan(&opt.ID, &opt.PollID, &opt.Text, &opt.CreatedAt, &opt.CreatedBy, &opt.UpdatedAt, &opt.UpdatedBy)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get poll option %s: %w", optionID, err)
	}
	return &opt, nil
}

func (r *pollRepository) VoteOption(ctx context.Context, pollID, optionID, userID string, allowMultiple bool) error {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			return r.VoteOption(txCtx, pollID, optionID, userID, allowMultiple)
		})
	}

	// Check if already voted for this specific option
	var count int
	checkQuery := `SELECT COUNT(*) FROM poll_votes WHERE poll_id = $1 AND option_id = $2 AND user_id = $3`
	err := tx.QueryRow(ctx, checkQuery, pollID, optionID, userID).Scan(&count)
	if err != nil {
		return fmt.Errorf("check existing vote for poll %s: %w", pollID, err)
	}

	if count > 0 {
		// Already voted for this option -> toggle it (remove vote)
		deleteQuery := `DELETE FROM poll_votes WHERE poll_id = $1 AND option_id = $2 AND user_id = $3`
		_, err = tx.Exec(ctx, deleteQuery, pollID, optionID, userID)
		if err != nil {
			return fmt.Errorf("toggle poll vote (remove) for poll %s: %w", pollID, err)
		}
	} else {
		// Does not have a vote for this specific option. Add vote.
		if !allowMultiple {
			// Remove any other existing votes for this user in this poll
			clearQuery := `DELETE FROM poll_votes WHERE poll_id = $1 AND user_id = $2`
			_, err = tx.Exec(ctx, clearQuery, pollID, userID)
			if err != nil {
				return fmt.Errorf("clear existing votes for poll %s: %w", pollID, err)
			}
		}

		insertQuery := `INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES ($1, $2, $3)`
		_, err = tx.Exec(ctx, insertQuery, pollID, optionID, userID)
		if err != nil {
			return fmt.Errorf("insert poll vote for poll %s: %w", pollID, err)
		}
	}

	return nil
}
