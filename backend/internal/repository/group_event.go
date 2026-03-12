package repository

import (
	"context"
	"fmt"

	"summitmate/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type GroupEventRepository interface {
	CreateEvent(ctx context.Context, event *model.GroupEvent) error
	GetEventByID(ctx context.Context, id string) (*model.GroupEvent, error)
	ListEvents(ctx context.Context, status *string, creatorID *string) ([]*model.GroupEvent, error)
	UpdateEvent(ctx context.Context, event *model.GroupEvent) error
	DeleteEvent(ctx context.Context, id string) error

	ApplyToEvent(ctx context.Context, app *model.GroupEventApplication) error
	ListApplications(ctx context.Context, eventID string) ([]*model.GroupEventApplication, error)
	UpdateApplicationStatus(ctx context.Context, eventID, userID, status, updatedBy string) error

	AddComment(ctx context.Context, comment *model.GroupEventComment) error
	ListComments(ctx context.Context, eventID string) ([]*model.GroupEventComment, error)
	DeleteComment(ctx context.Context, commentID string, userID string) error

	ToggleLike(ctx context.Context, eventID, userID string) (bool, error)
}

type groupEventRepository struct {
	db *pgxpool.Pool
}

func NewGroupEventRepository(db *pgxpool.Pool) GroupEventRepository {
	return &groupEventRepository{db: db}
}

func (r *groupEventRepository) CreateEvent(ctx context.Context, event *model.GroupEvent) error {
	query := `
		INSERT INTO group_events (
			title, description, location, start_date, end_date,
			max_members, approval_required, private_message, linked_trip_id,
			created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
		) RETURNING id, status, like_count, comment_count, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query,
		event.Title, event.Description, event.Location, event.StartDate, event.EndDate,
		event.MaxMembers, event.ApprovalRequired, event.PrivateMessage, event.LinkedTripID,
		event.CreatedBy, event.UpdatedBy,
	).Scan(&event.ID, &event.Status, &event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to create group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) GetEventByID(ctx context.Context, id string) (*model.GroupEvent, error) {
	query := `
		SELECT id, title, description, location, start_date, end_date,
            status, max_members, approval_required, private_message, linked_trip_id,
            like_count, comment_count, created_at, created_by, updated_at, updated_by
		FROM group_events
		WHERE id = $1
	`
	event := &model.GroupEvent{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&event.ID, &event.Title, &event.Description, &event.Location, &event.StartDate, &event.EndDate,
		&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
		&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get group event: %w", err)
	}
	return event, nil
}

func (r *groupEventRepository) ListEvents(ctx context.Context, status *string, creatorID *string) ([]*model.GroupEvent, error) {
	query := `
		SELECT id, title, description, location, start_date, end_date,
            status, max_members, approval_required, private_message, linked_trip_id,
            like_count, comment_count, created_at, created_by, updated_at, updated_by
		FROM group_events
		WHERE 1=1
	`
	args := []interface{}{}
	argCount := 1

	if status != nil {
		query += fmt.Sprintf(" AND status = $%d", argCount)
		args = append(args, *status)
		argCount++
	}
	if creatorID != nil {
		query += fmt.Sprintf(" AND created_by = $%d", argCount)
		args = append(args, *creatorID)
		argCount++
	}

	query += " ORDER BY created_at DESC"

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list group events: %w", err)
	}
	defer rows.Close()

	var events []*model.GroupEvent
	for rows.Next() {
		event := &model.GroupEvent{}
		err := rows.Scan(
			&event.ID, &event.Title, &event.Description, &event.Location, &event.StartDate, &event.EndDate,
			&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
			&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan group event: %w", err)
		}
		events = append(events, event)
	}
	return events, nil
}

func (r *groupEventRepository) UpdateEvent(ctx context.Context, event *model.GroupEvent) error {
	query := `
		UPDATE group_events
		SET title = $1, description = $2, location = $3, start_date = $4, end_date = $5,
            max_members = $6, approval_required = $7, private_message = $8, linked_trip_id = $9,
            updated_at = NOW(), updated_by = $10
		WHERE id = $11
		RETURNING updated_at
	`
	err := r.db.QueryRow(ctx, query,
		event.Title, event.Description, event.Location, event.StartDate, event.EndDate,
		event.MaxMembers, event.ApprovalRequired, event.PrivateMessage, event.LinkedTripID,
		event.UpdatedBy, event.ID,
	).Scan(&event.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to update group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) DeleteEvent(ctx context.Context, id string) error {
	query := `DELETE FROM group_events WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) ApplyToEvent(ctx context.Context, app *model.GroupEventApplication) error {
	query := `
		INSERT INTO group_event_applications (
			event_id, user_id, message, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5)
		RETURNING id, status, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query,
		app.EventID, app.UserID, app.Message, app.CreatedBy, app.UpdatedBy,
	).Scan(&app.ID, &app.Status, &app.CreatedAt, &app.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to apply to group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) ListApplications(ctx context.Context, eventID string) ([]*model.GroupEventApplication, error) {
	query := `
		SELECT id, event_id, user_id, status, message, created_at, created_by, updated_at, updated_by
		FROM group_event_applications
		WHERE event_id = $1
		ORDER BY created_at ASC
	`
	rows, err := r.db.Query(ctx, query, eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to list applications: %w", err)
	}
	defer rows.Close()

	var apps []*model.GroupEventApplication
	for rows.Next() {
		app := &model.GroupEventApplication{}
		err := rows.Scan(
			&app.ID, &app.EventID, &app.UserID, &app.Status, &app.Message,
			&app.CreatedAt, &app.CreatedBy, &app.UpdatedAt, &app.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan application: %w", err)
		}
		apps = append(apps, app)
	}
	return apps, nil
}

func (r *groupEventRepository) UpdateApplicationStatus(ctx context.Context, eventID, userID, status, updatedBy string) error {
	query := `
		UPDATE group_event_applications
		SET status = $1, updated_at = NOW(), updated_by = $2
		WHERE event_id = $3 AND user_id = $4
	`
	_, err := r.db.Exec(ctx, query, status, updatedBy, eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to update application status: %w", err)
	}
	return nil
}

func (r *groupEventRepository) AddComment(ctx context.Context, comment *model.GroupEventComment) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
		INSERT INTO group_event_comments (
			event_id, user_id, content, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`
	err = tx.QueryRow(ctx, query,
		comment.EventID, comment.UserID, comment.Content, comment.CreatedBy, comment.UpdatedBy,
	).Scan(&comment.ID, &comment.CreatedAt, &comment.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to insert comment: %w", err)
	}

	_, err = tx.Exec(ctx, "UPDATE group_events SET comment_count = comment_count + 1 WHERE id = $1", comment.EventID)
	if err != nil {
		return fmt.Errorf("failed to increment comment count: %w", err)
	}

	return tx.Commit(ctx)
}

func (r *groupEventRepository) ListComments(ctx context.Context, eventID string) ([]*model.GroupEventComment, error) {
	query := `
		SELECT c.id, c.event_id, c.user_id, c.content,
		       c.created_at, c.created_by, c.updated_at, c.updated_by,
		       u.display_name, u.avatar
		FROM group_event_comments c
		JOIN users u ON c.user_id = u.id
		WHERE c.event_id = $1
		ORDER BY c.created_at ASC
	`
	rows, err := r.db.Query(ctx, query, eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to list comments: %w", err)
	}
	defer rows.Close()

	var comments []*model.GroupEventComment
	for rows.Next() {
		c := &model.GroupEventComment{}
		err := rows.Scan(
			&c.ID, &c.EventID, &c.UserID, &c.Content,
			&c.CreatedAt, &c.CreatedBy, &c.UpdatedAt, &c.UpdatedBy,
			&c.DisplayName, &c.Avatar,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan comment: %w", err)
		}
		comments = append(comments, c)
	}
	return comments, nil
}

func (r *groupEventRepository) DeleteComment(ctx context.Context, commentID string, userID string) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var eventID string
	err = tx.QueryRow(ctx, "DELETE FROM group_event_comments WHERE id = $1 AND user_id = $2 RETURNING event_id", commentID, userID).Scan(&eventID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return fmt.Errorf("comment not found or unauthorized")
		}
		return fmt.Errorf("failed to delete comment: %w", err)
	}

	_, err = tx.Exec(ctx, "UPDATE group_events SET comment_count = comment_count - 1 WHERE id = $1", eventID)
	if err != nil {
		return fmt.Errorf("failed to decrement comment count: %w", err)
	}

	return tx.Commit(ctx)
}

func (r *groupEventRepository) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)

	var isLiked bool
	var exists bool
	err = tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = $1 AND user_id = $2)", eventID, userID).Scan(&exists)
	if err != nil {
		return false, err
	}

	if exists {
		_, err = tx.Exec(ctx, "DELETE FROM group_event_likes WHERE event_id = $1 AND user_id = $2", eventID, userID)
		if err != nil {
			return false, err
		}
		_, err = tx.Exec(ctx, "UPDATE group_events SET like_count = like_count - 1 WHERE id = $1", eventID)
		if err != nil {
			return false, err
		}
		isLiked = false
	} else {
		_, err = tx.Exec(ctx, "INSERT INTO group_event_likes (event_id, user_id, created_by) VALUES ($1, $2, $2)", eventID, userID)
		if err != nil {
			return false, err
		}
		_, err = tx.Exec(ctx, "UPDATE group_events SET like_count = like_count + 1 WHERE id = $1", eventID)
		if err != nil {
			return false, err
		}
		isLiked = true
	}

	err = tx.Commit(ctx)
	return isLiked, err
}
