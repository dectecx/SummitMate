package groupevent

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

type GroupEventRepository interface {
	CreateEvent(ctx context.Context, event *GroupEvent) error
	GetEventByID(ctx context.Context, id string) (*GroupEvent, error)
	ListEvents(ctx context.Context, status *string, creatorID *string, page int, limit int, search string) ([]*GroupEvent, int, bool, error)
	UpdateEvent(ctx context.Context, event *GroupEvent) error
	DeleteEvent(ctx context.Context, id string) error

	ApplyToEvent(ctx context.Context, app *GroupEventApplication) error
	ListApplications(ctx context.Context, eventID string) ([]*GroupEventApplication, error)
	UpdateApplicationStatus(ctx context.Context, eventID, userID, status, updatedBy string) error

	AddComment(ctx context.Context, comment *GroupEventComment) error
	ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error)
	DeleteComment(ctx context.Context, commentID string, userID string) error

	ToggleLike(ctx context.Context, eventID, userID string) (bool, error)
}

type groupEventRepository struct {
	db database.DB
}

func NewGroupEventRepository(db database.DB) GroupEventRepository {
	return &groupEventRepository{db: db}
}

func (r *groupEventRepository) CreateEvent(ctx context.Context, event *GroupEvent) error {
	query := `
		INSERT INTO group_events (
			title, description, location, start_date, end_date,
			max_members, approval_required, private_message, linked_trip_id,
			created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
		) RETURNING id, status, like_count, comment_count, created_at, updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		event.Title, event.Description, event.Location, event.StartDate, event.EndDate,
		event.MaxMembers, event.ApprovalRequired, event.PrivateMessage, event.LinkedTripID,
		event.CreatedBy, event.UpdatedBy,
	).Scan(&event.ID, &event.Status, &event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.UpdatedAt)
	if err != nil {
		return fmt.Errorf("create group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) GetEventByID(ctx context.Context, id string) (*GroupEvent, error) {
	query := `
		SELECT id, title, description, location, start_date, end_date,
            status, max_members, approval_required, private_message, linked_trip_id,
            like_count, comment_count, created_at, created_by, updated_at, updated_by
		FROM group_events
		WHERE id = $1
	`
	event := &GroupEvent{}
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, id).Scan(
		&event.ID, &event.Title, &event.Description, &event.Location, &event.StartDate, &event.EndDate,
		&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
		&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get group event %s: %w", id, err)
	}
	return event, nil
}

func (r *groupEventRepository) ListEvents(ctx context.Context, status *string, creatorID *string, page int, limit int, search string) ([]*GroupEvent, int, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}

	whereClause := "WHERE 1=1"
	args := []any{}

	if status != nil {
		args = append(args, *status)
		whereClause += fmt.Sprintf(" AND status = $%d", len(args))
	}
	if creatorID != nil {
		args = append(args, *creatorID)
		whereClause += fmt.Sprintf(" AND created_by = $%d", len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		whereClause += fmt.Sprintf(" AND title ILIKE $%d", len(args))
	}

	db := database.GetQuerier(ctx, r.db)
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM group_events %s", whereClause)
	if err := db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, false, fmt.Errorf("count group events: %w", err)
	}

	dataArgs := append(args, limit, (page-1)*limit)
	mainQuery := fmt.Sprintf(`
		SELECT id, title, description, location, start_date, end_date,
			status, max_members, approval_required, private_message, linked_trip_id,
			like_count, comment_count, created_at, created_by, updated_at, updated_by
		FROM group_events
		%s
		ORDER BY created_at DESC, id DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, len(args)+1, len(args)+2)

	rows, err := db.Query(ctx, mainQuery, dataArgs...)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query group events: %w", err)
	}
	defer rows.Close()

	var events []*GroupEvent
	for rows.Next() {
		event := &GroupEvent{}
		err := rows.Scan(
			&event.ID, &event.Title, &event.Description, &event.Location, &event.StartDate, &event.EndDate,
			&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
			&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
		)
		if err != nil {
			return nil, 0, false, fmt.Errorf("scan group event row: %w", err)
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, false, fmt.Errorf("iterate group event rows: %w", err)
	}

	return events, total, page*limit < total, nil
}

func (r *groupEventRepository) UpdateEvent(ctx context.Context, event *GroupEvent) error {
	query := `
		UPDATE group_events
		SET title = $1, description = $2, location = $3, start_date = $4, end_date = $5,
            max_members = $6, approval_required = $7, private_message = $8, linked_trip_id = $9,
            updated_at = NOW(), updated_by = $10
		WHERE id = $11
		RETURNING updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		event.Title, event.Description, event.Location, event.StartDate, event.EndDate,
		event.MaxMembers, event.ApprovalRequired, event.PrivateMessage, event.LinkedTripID,
		event.UpdatedBy, event.ID,
	).Scan(&event.UpdatedAt)
	if err != nil {
		return fmt.Errorf("update group event %s: %w", event.ID, err)
	}
	return nil
}

func (r *groupEventRepository) DeleteEvent(ctx context.Context, id string) error {
	query := `DELETE FROM group_events WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("delete group event %s: %w", id, err)
	}
	return nil
}

func (r *groupEventRepository) ApplyToEvent(ctx context.Context, app *GroupEventApplication) error {
	query := `
		INSERT INTO group_event_applications (
			event_id, user_id, message, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5)
		RETURNING id, status, created_at, updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		app.EventID, app.UserID, app.Message, app.CreatedBy, app.UpdatedBy,
	).Scan(&app.ID, &app.Status, &app.CreatedAt, &app.UpdatedAt)
	if err != nil {
		return fmt.Errorf("apply to group event %s by user %s: %w", app.EventID, app.UserID, err)
	}
	return nil
}

func (r *groupEventRepository) ListApplications(ctx context.Context, eventID string) ([]*GroupEventApplication, error) {
	query := `
		SELECT id, event_id, user_id, status, message, created_at, created_by, updated_at, updated_by
		FROM group_event_applications
		WHERE event_id = $1
		ORDER BY created_at ASC
	`
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, query, eventID)
	if err != nil {
		return nil, fmt.Errorf("list applications for group event %s: %w", eventID, err)
	}
	defer rows.Close()

	var apps []*GroupEventApplication
	for rows.Next() {
		app := &GroupEventApplication{}
		err := rows.Scan(
			&app.ID, &app.EventID, &app.UserID, &app.Status, &app.Message,
			&app.CreatedAt, &app.CreatedBy, &app.UpdatedAt, &app.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("scan application row: %w", err)
		}
		apps = append(apps, app)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate application rows: %w", err)
	}
	return apps, nil
}

func (r *groupEventRepository) UpdateApplicationStatus(ctx context.Context, eventID, userID, status, updatedBy string) error {
	query := `
		UPDATE group_event_applications
		SET status = $1, updated_at = NOW(), updated_by = $2
		WHERE event_id = $3 AND user_id = $4
	`
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, status, updatedBy, eventID, userID)
	if err != nil {
		return fmt.Errorf("update application status for event %s, user %s: %w", eventID, userID, err)
	}
	return nil
}

func (r *groupEventRepository) AddComment(ctx context.Context, comment *GroupEventComment) error {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			return r.AddComment(txCtx, comment)
		})
	}

	query := `
		INSERT INTO group_event_comments (
			event_id, user_id, content, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`
	err := tx.QueryRow(ctx, query,
		comment.EventID, comment.UserID, comment.Content, comment.CreatedBy, comment.UpdatedBy,
	).Scan(&comment.ID, &comment.CreatedAt, &comment.UpdatedAt)
	if err != nil {
		return fmt.Errorf("insert comment to event %s: %w", comment.EventID, err)
	}

	_, err = tx.Exec(ctx, "UPDATE group_events SET comment_count = comment_count + 1 WHERE id = $1", comment.EventID)
	if err != nil {
		return fmt.Errorf("increment comment count for event %s: %w", comment.EventID, err)
	}

	return nil
}

func (r *groupEventRepository) ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error) {
	query := `
		SELECT c.id, c.event_id, c.user_id, c.content,
		       c.created_at, c.created_by, c.updated_at, c.updated_by,
		       u.display_name, u.avatar
		FROM group_event_comments c
		JOIN users u ON c.user_id = u.id
		WHERE c.event_id = $1
		ORDER BY c.created_at ASC
	`
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, query, eventID)
	if err != nil {
		return nil, fmt.Errorf("list comments for event %s: %w", eventID, err)
	}
	defer rows.Close()

	var comments []*GroupEventComment
	for rows.Next() {
		c := &GroupEventComment{}
		err := rows.Scan(
			&c.ID, &c.EventID, &c.UserID, &c.Content,
			&c.CreatedAt, &c.CreatedBy, &c.UpdatedAt, &c.UpdatedBy,
			&c.DisplayName, &c.Avatar,
		)
		if err != nil {
			return nil, fmt.Errorf("scan comment row: %w", err)
		}
		comments = append(comments, c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate comment rows: %w", err)
	}
	return comments, nil
}

func (r *groupEventRepository) DeleteComment(ctx context.Context, commentID string, userID string) error {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			return r.DeleteComment(txCtx, commentID, userID)
		})
	}

	var eventID string
	err := tx.QueryRow(ctx, "DELETE FROM group_event_comments WHERE id = $1 AND user_id = $2 RETURNING event_id", commentID, userID).Scan(&eventID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("comment %s not found or unauthorized", commentID)
		}
		return fmt.Errorf("delete comment %s: %w", commentID, err)
	}

	_, err = tx.Exec(ctx, "UPDATE group_events SET comment_count = comment_count - 1 WHERE id = $1", eventID)
	if err != nil {
		return fmt.Errorf("decrement comment count for event %s: %w", eventID, err)
	}

	return nil
}

func (r *groupEventRepository) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		var isLiked bool
		err := database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			var err error
			isLiked, err = r.ToggleLike(txCtx, eventID, userID)
			return err
		})
		return isLiked, err
	}

	var exists bool
	err := tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = $1 AND user_id = $2)", eventID, userID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check existing like for event %s, user %s: %w", eventID, userID, err)
	}

	var isLiked bool
	if exists {
		_, err = tx.Exec(ctx, "DELETE FROM group_event_likes WHERE event_id = $1 AND user_id = $2", eventID, userID)
		if err != nil {
			return false, fmt.Errorf("delete like for event %s, user %s: %w", eventID, userID, err)
		}
		_, err = tx.Exec(ctx, "UPDATE group_events SET like_count = like_count - 1 WHERE id = $1", eventID)
		if err != nil {
			return false, fmt.Errorf("decrement like count for event %s: %w", eventID, err)
		}
		isLiked = false
	} else {
		_, err = tx.Exec(ctx, "INSERT INTO group_event_likes (event_id, user_id, created_by) VALUES ($1, $2, $2)", eventID, userID)
		if err != nil {
			return false, fmt.Errorf("insert like for event %s, user %s: %w", eventID, userID, err)
		}
		_, err = tx.Exec(ctx, "UPDATE group_events SET like_count = like_count + 1 WHERE id = $1", eventID)
		if err != nil {
			return false, fmt.Errorf("increment like count for event %s: %w", eventID, err)
		}
		isLiked = true
	}

	return isLiked, nil
}
