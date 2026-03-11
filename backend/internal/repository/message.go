package repository

import (
	"context"
	"fmt"
	"time"

	"summitmate/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type MessageRepository interface {
	ListTripMessages(ctx context.Context, tripID string) ([]*model.TripMessage, error)
	CreateMessage(ctx context.Context, msg *model.TripMessage) error
	GetMessageByID(ctx context.Context, messageID string) (*model.TripMessage, error)
	UpdateMessage(ctx context.Context, msg *model.TripMessage) error
	DeleteMessage(ctx context.Context, messageID string) error
}

type messageRepository struct {
	db *pgxpool.Pool
}

func NewMessageRepository(db *pgxpool.Pool) MessageRepository {
	return &messageRepository{db: db}
}

func (r *messageRepository) ListTripMessages(ctx context.Context, tripID string) ([]*model.TripMessage, error) {
	query := `
		SELECT
			m.id, m.trip_id, m.parent_id, m.user_id, u.display_name, u.avatar,
			m.category, m.content, m.timestamp, m.created_at, m.created_by, m.updated_at, m.updated_by
		FROM messages m
		JOIN users u ON m.user_id = u.id
		WHERE m.trip_id = $1
		ORDER BY m.timestamp ASC
	`
	rows, err := r.db.Query(ctx, query, tripID)
	if err != nil {
		return nil, fmt.Errorf("failed to list trip messages: %w", err)
	}
	defer rows.Close()

	var messages []*model.TripMessage
	for rows.Next() {
		var msg model.TripMessage
		err := rows.Scan(
			&msg.ID, &msg.TripID, &msg.ParentID, &msg.UserID, &msg.DisplayName, &msg.Avatar,
			&msg.Category, &msg.Content, &msg.Timestamp, &msg.CreatedAt, &msg.CreatedBy, &msg.UpdatedAt, &msg.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan trip message: %w", err)
		}
		msg.Replies = []*model.TripMessage{}
		messages = append(messages, &msg)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return messages, nil
}

func (r *messageRepository) CreateMessage(ctx context.Context, msg *model.TripMessage) error {
	query := `
		INSERT INTO messages (
			trip_id, parent_id, user_id, category, content, timestamp, created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		) RETURNING id, created_at, updated_at
	`
	var id string
	var createdAt, updatedAt time.Time
	err := r.db.QueryRow(ctx, query,
		msg.TripID, msg.ParentID, msg.UserID, msg.Category, msg.Content, msg.Timestamp, msg.CreatedBy, msg.UpdatedBy,
	).Scan(&id, &createdAt, &updatedAt)
	if err != nil {
		return fmt.Errorf("failed to create message: %w", err)
	}

	msg.ID = id
	msg.CreatedAt = createdAt
	msg.UpdatedAt = updatedAt

	// Fetch User info string immediately
	userQuery := `SELECT display_name, avatar FROM users WHERE id = $1`
	err = r.db.QueryRow(ctx, userQuery, msg.UserID).Scan(&msg.DisplayName, &msg.Avatar)
	if err != nil {
		return fmt.Errorf("failed to fetch user info for new message: %w", err)
	}

	return nil
}

func (r *messageRepository) GetMessageByID(ctx context.Context, messageID string) (*model.TripMessage, error) {
	query := `
		SELECT
			m.id, m.trip_id, m.parent_id, m.user_id, u.display_name, u.avatar,
			m.category, m.content, m.timestamp, m.created_at, m.created_by, m.updated_at, m.updated_by
		FROM messages m
		JOIN users u ON m.user_id = u.id
		WHERE m.id = $1
	`
	var msg model.TripMessage
	err := r.db.QueryRow(ctx, query, messageID).Scan(
		&msg.ID, &msg.TripID, &msg.ParentID, &msg.UserID, &msg.DisplayName, &msg.Avatar,
		&msg.Category, &msg.Content, &msg.Timestamp, &msg.CreatedAt, &msg.CreatedBy, &msg.UpdatedAt, &msg.UpdatedBy,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil // Not found
		}
		return nil, fmt.Errorf("failed to get message: %w", err)
	}
	return &msg, nil
}

func (r *messageRepository) UpdateMessage(ctx context.Context, msg *model.TripMessage) error {
	query := `
		UPDATE messages
		SET category = $1, content = $2, updated_at = NOW(), updated_by = $3
		WHERE id = $4
		RETURNING updated_at
	`
	var updatedAt time.Time
	err := r.db.QueryRow(ctx, query, msg.Category, msg.Content, msg.UpdatedBy, msg.ID).Scan(&updatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return fmt.Errorf("message not found")
		}
		return fmt.Errorf("failed to update message: %w", err)
	}
	msg.UpdatedAt = updatedAt
	return nil
}

func (r *messageRepository) DeleteMessage(ctx context.Context, messageID string) error {
	query := `DELETE FROM messages WHERE id = $1`
	cmd, err := r.db.Exec(ctx, query, messageID)
	if err != nil {
		return fmt.Errorf("failed to delete message: %w", err)
	}
	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("message not found")
	}
	return nil
}
