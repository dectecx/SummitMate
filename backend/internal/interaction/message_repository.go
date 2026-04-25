package interaction

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

type MessageRepository interface {
	ListTripMessages(ctx context.Context, tripID string) ([]*TripMessage, error)
	CreateMessage(ctx context.Context, msg *TripMessage) error
	GetMessageByID(ctx context.Context, messageID string) (*TripMessage, error)
	UpdateMessage(ctx context.Context, msg *TripMessage) error
	DeleteMessage(ctx context.Context, messageID string) error
}

type messageRepository struct {
	db database.DB
}

func NewMessageRepository(db database.DB) MessageRepository {
	return &messageRepository{db: db}
}

func (r *messageRepository) ListTripMessages(ctx context.Context, tripID string) ([]*TripMessage, error) {
	query := `
		SELECT
			m.id, m.trip_id, m.parent_id, m.user_id, u.display_name, u.avatar,
			m.category, m.content, m.timestamp, m.created_at, m.created_by, m.updated_at, m.updated_by
		FROM messages m
		JOIN users u ON m.user_id = u.id
		WHERE m.trip_id = $1
		ORDER BY m.timestamp ASC
	`
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, fmt.Errorf("list trip messages for trip %s: %w", tripID, err)
	}
	defer rows.Close()

	var messages []*TripMessage
	for rows.Next() {
		var msg TripMessage
		err := rows.Scan(
			&msg.ID, &msg.TripID, &msg.ParentID, &msg.UserID, &msg.DisplayName, &msg.Avatar,
			&msg.Category, &msg.Content, &msg.Timestamp, &msg.CreatedAt, &msg.CreatedBy, &msg.UpdatedAt, &msg.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("scan trip message row: %w", err)
		}
		msg.Replies = []*TripMessage{}
		messages = append(messages, &msg)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate trip message rows: %w", err)
	}

	return messages, nil
}

func (r *messageRepository) CreateMessage(ctx context.Context, msg *TripMessage) error {
	query := `
		INSERT INTO messages (
			trip_id, parent_id, user_id, category, content, timestamp, created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		) RETURNING id, created_at, updated_at
	`
	var id string
	var createdAt, updatedAt time.Time
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		msg.TripID, msg.ParentID, msg.UserID, msg.Category, msg.Content, msg.Timestamp, msg.CreatedBy, msg.UpdatedBy,
	).Scan(&id, &createdAt, &updatedAt)
	if err != nil {
		return fmt.Errorf("create message for trip %s: %w", msg.TripID, err)
	}

	msg.ID = id
	msg.CreatedAt = createdAt
	msg.UpdatedAt = updatedAt

	// Fetch User info string immediately
	userQuery := `SELECT display_name, avatar FROM users WHERE id = $1`
	err = db.QueryRow(ctx, userQuery, msg.UserID).Scan(&msg.DisplayName, &msg.Avatar)
	if err != nil {
		return fmt.Errorf("fetch user info for new message %s: %w", msg.ID, err)
	}

	return nil
}

func (r *messageRepository) GetMessageByID(ctx context.Context, messageID string) (*TripMessage, error) {
	query := `
		SELECT
			m.id, m.trip_id, m.parent_id, m.user_id, u.display_name, u.avatar,
			m.category, m.content, m.timestamp, m.created_at, m.created_by, m.updated_at, m.updated_by
		FROM messages m
		JOIN users u ON m.user_id = u.id
		WHERE m.id = $1
	`
	var msg TripMessage
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, messageID).Scan(
		&msg.ID, &msg.TripID, &msg.ParentID, &msg.UserID, &msg.DisplayName, &msg.Avatar,
		&msg.Category, &msg.Content, &msg.Timestamp, &msg.CreatedAt, &msg.CreatedBy, &msg.UpdatedAt, &msg.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil // Not found
		}
		return nil, fmt.Errorf("get message %s: %w", messageID, err)
	}
	return &msg, nil
}

func (r *messageRepository) UpdateMessage(ctx context.Context, msg *TripMessage) error {
	query := `
		UPDATE messages
		SET category = $1, content = $2, updated_at = NOW(), updated_by = $3
		WHERE id = $4
		RETURNING updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	var updatedAt time.Time
	err := db.QueryRow(ctx, query, msg.Category, msg.Content, msg.UpdatedBy, msg.ID).Scan(&updatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("message %s not found", msg.ID)
		}
		return fmt.Errorf("update message %s: %w", msg.ID, err)
	}
	msg.UpdatedAt = updatedAt
	return nil
}

func (r *messageRepository) DeleteMessage(ctx context.Context, messageID string) error {
	query := `DELETE FROM messages WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	cmd, err := db.Exec(ctx, query, messageID)
	if err != nil {
		return fmt.Errorf("delete message %s: %w", messageID, err)
	}
	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("message %s not found", messageID)
	}
	return nil
}
