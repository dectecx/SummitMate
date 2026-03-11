package repository

import (
	"context"
	"fmt"
	"time"

	"summitmate/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PollRepository interface {
	CreatePoll(ctx context.Context, poll *model.Poll) error
	GetPollByID(ctx context.Context, pollID string) (*model.Poll, error)
	ListTripPolls(ctx context.Context, tripID string) ([]*model.Poll, error)
	DeletePoll(ctx context.Context, pollID string) error

	AddPollOption(ctx context.Context, option *model.PollOption) error
	GetPollOption(ctx context.Context, optionID string) (*model.PollOption, error)

	VoteOption(ctx context.Context, pollID, optionID, userID string, allowMultiple bool) error
}

type pollRepository struct {
	db *pgxpool.Pool
}

func NewPollRepository(db *pgxpool.Pool) PollRepository {
	return &pollRepository{db: db}
}

func (r *pollRepository) CreatePoll(ctx context.Context, poll *model.Poll) error {
	query := `
		INSERT INTO polls (
			trip_id, title, description, creator_id, deadline,
			is_allow_add_option, max_option_limit, allow_multiple_votes,
			result_display_type, status, created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
		) RETURNING id, created_at, updated_at
	`
	var id string
	var createdAt, updatedAt time.Time

	err := r.db.QueryRow(ctx, query,
		poll.TripID, poll.Title, poll.Description, poll.CreatorID, poll.Deadline,
		poll.IsAllowAddOption, poll.MaxOptionLimit, poll.AllowMultipleVotes,
		poll.ResultDisplayType, poll.Status, poll.CreatedBy, poll.UpdatedBy,
	).Scan(&id, &createdAt, &updatedAt)
	if err != nil {
		return fmt.Errorf("failed to create poll: %w", err)
	}

	poll.ID = id
	poll.CreatedAt = createdAt
	poll.UpdatedAt = updatedAt
	poll.Options = []*model.PollOption{}
	return nil
}

func (r *pollRepository) loadPollOptions(ctx context.Context, pollID string) ([]*model.PollOption, error) {
	// First fetch all options
	optQuery := `SELECT id, poll_id, text, creator_id FROM poll_options WHERE poll_id = $1 ORDER BY created_at ASC`
	rows, err := r.db.Query(ctx, optQuery, pollID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch options: %w", err)
	}
	defer rows.Close()

	var options []*model.PollOption
	optMap := make(map[string]*model.PollOption)
	for rows.Next() {
		var opt model.PollOption
		if err := rows.Scan(&opt.ID, &opt.PollID, &opt.Text, &opt.CreatorID); err != nil {
			return nil, err
		}
		opt.Voters = []string{}
		options = append(options, &opt)
		optMap[opt.ID] = &opt
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Then fetch votes for those options
	if len(options) > 0 {
		voteQuery := `SELECT option_id, user_id FROM poll_votes WHERE poll_id = $1`
		vRows, err := r.db.Query(ctx, voteQuery, pollID)
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

func (r *pollRepository) GetPollByID(ctx context.Context, pollID string) (*model.Poll, error) {
	query := `
		SELECT id, trip_id, title, description, creator_id, deadline,
		is_allow_add_option, max_option_limit, allow_multiple_votes,
		result_display_type, status, created_at, created_by, updated_at, updated_by
		FROM polls WHERE id = $1
	`
	var p model.Poll
	err := r.db.QueryRow(ctx, query, pollID).Scan(
		&p.ID, &p.TripID, &p.Title, &p.Description, &p.CreatorID, &p.Deadline,
		&p.IsAllowAddOption, &p.MaxOptionLimit, &p.AllowMultipleVotes,
		&p.ResultDisplayType, &p.Status, &p.CreatedAt, &p.CreatedBy, &p.UpdatedAt, &p.UpdatedBy,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	options, err := r.loadPollOptions(ctx, p.ID)
	if err != nil {
		return nil, err
	}
	p.Options = options

	return &p, nil
}

func (r *pollRepository) ListTripPolls(ctx context.Context, tripID string) ([]*model.Poll, error) {
	query := `
		SELECT id, trip_id, title, description, creator_id, deadline,
		is_allow_add_option, max_option_limit, allow_multiple_votes,
		result_display_type, status, created_at, created_by, updated_at, updated_by
		FROM polls WHERE trip_id = $1
		ORDER BY created_at DESC
	`
	rows, err := r.db.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var polls []*model.Poll
	for rows.Next() {
		var p model.Poll
		if err := rows.Scan(
			&p.ID, &p.TripID, &p.Title, &p.Description, &p.CreatorID, &p.Deadline,
			&p.IsAllowAddOption, &p.MaxOptionLimit, &p.AllowMultipleVotes,
			&p.ResultDisplayType, &p.Status, &p.CreatedAt, &p.CreatedBy, &p.UpdatedAt, &p.UpdatedBy,
		); err != nil {
			return nil, err
		}
		polls = append(polls, &p)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	for _, p := range polls {
		options, err := r.loadPollOptions(ctx, p.ID)
		if err == nil {
			p.Options = options
		} else {
			p.Options = []*model.PollOption{}
		}
	}

	return polls, nil
}

func (r *pollRepository) DeletePoll(ctx context.Context, pollID string) error {
	query := `DELETE FROM polls WHERE id = $1`
	cmd, err := r.db.Exec(ctx, query, pollID)
	if err != nil {
		return err
	}
	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("poll not found")
	}
	return nil
}

func (r *pollRepository) AddPollOption(ctx context.Context, option *model.PollOption) error {
	query := `
		INSERT INTO poll_options (poll_id, text, creator_id)
		VALUES ($1, $2, $3)
		RETURNING id
	`
	err := r.db.QueryRow(ctx, query, option.PollID, option.Text, option.CreatorID).Scan(&option.ID)
	if err != nil {
		return fmt.Errorf("failed to add poll option: %w", err)
	}
	option.Voters = []string{}
	option.VoteCount = 0
	return nil
}

func (r *pollRepository) GetPollOption(ctx context.Context, optionID string) (*model.PollOption, error) {
	query := `SELECT id, poll_id, text, creator_id FROM poll_options WHERE id = $1`
	var opt model.PollOption
	err := r.db.QueryRow(ctx, query, optionID).Scan(&opt.ID, &opt.PollID, &opt.Text, &opt.CreatorID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &opt, nil
}

func (r *pollRepository) VoteOption(ctx context.Context, pollID, optionID, userID string, allowMultiple bool) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Check if already voted for this specific option
	var count int
	checkQuery := `SELECT COUNT(*) FROM poll_votes WHERE poll_id = $1 AND option_id = $2 AND user_id = $3`
	err = tx.QueryRow(ctx, checkQuery, pollID, optionID, userID).Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		// Already voted for this option -> toggle it (remove vote)
		deleteQuery := `DELETE FROM poll_votes WHERE poll_id = $1 AND option_id = $2 AND user_id = $3`
		_, err = tx.Exec(ctx, deleteQuery, pollID, optionID, userID)
		if err != nil {
			return err
		}
	} else {
		// Does not have a vote for this specific option. Add vote.
		if !allowMultiple {
			// Remove any other existing votes for this user in this poll
			clearQuery := `DELETE FROM poll_votes WHERE poll_id = $1 AND user_id = $2`
			_, err = tx.Exec(ctx, clearQuery, pollID, userID)
			if err != nil {
				return err
			}
		}

		insertQuery := `INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES ($1, $2, $3)`
		_, err = tx.Exec(ctx, insertQuery, pollID, optionID, userID)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}
