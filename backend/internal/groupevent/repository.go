package groupevent

import (
	"context"
	"errors"
	"fmt"

	"summitmate/internal/database"

	"github.com/jackc/pgx/v5"
)

type GroupEventRepository interface {
	CreateEvent(ctx context.Context, event *GroupEvent) error
	GetEventByID(ctx context.Context, id string, userID string) (*GroupEvent, error)
	ListEvents(ctx context.Context, status *string, category *Category, hostID *string, page int, limit int, search string, userID string) ([]*GroupEvent, int, bool, error)
	ListEventsByUser(ctx context.Context, userID string, listType string, page int, limit int) ([]*GroupEvent, int, bool, error)
	UpdateEvent(ctx context.Context, event *GroupEvent) error
	DeleteEvent(ctx context.Context, id string) error

	ApplyToEvent(ctx context.Context, app *GroupEventApplication) error
	GetApplicationByID(ctx context.Context, id string) (*GroupEventApplication, error)
	ListApplications(ctx context.Context, eventID string) ([]*GroupEventApplication, error)
	UpdateApplicationStatus(ctx context.Context, id, status, rejectionReason, updatedBy string) error
	GetPendingApplicationByEventAndUser(ctx context.Context, eventID, userID string) (*GroupEventApplication, error)
	DeleteApplication(ctx context.Context, id string) error
	GetCommentByID(ctx context.Context, id string) (*GroupEventComment, error)

	AddComment(ctx context.Context, comment *GroupEventComment) error
	ListComments(ctx context.Context, eventID string) ([]*GroupEventComment, error)
	DeleteComment(ctx context.Context, commentID string, userID string) error

	ToggleLike(ctx context.Context, eventID, userID string) (bool, error)
	UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error
	UpdateTripSnapshot(ctx context.Context, eventID string, snapshot *TripSnapshot, userID string) error
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
            host_id, host_name, host_avatar,
            title, description, category, location, start_date, end_date,
            max_members, approval_required, private_message, linked_trip_id,
            created_by, updated_by
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
        ) RETURNING id, status, like_count, comment_count, created_at, updated_at
    `
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		event.HostID, event.HostName, event.HostAvatar,
		event.Title, event.Description, event.Category, event.Location, event.StartDate, event.EndDate,
		event.MaxMembers, event.ApprovalRequired, event.PrivateMessage, event.LinkedTripID,
		event.CreatedBy, event.UpdatedBy,
	).Scan(&event.ID, &event.Status, &event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.UpdatedAt)
	if err != nil {
		return fmt.Errorf("create group event: %w", err)
	}
	return nil
}

func (r *groupEventRepository) GetEventByID(ctx context.Context, id string, userID string) (*GroupEvent, error) {
	query := `
        SELECT
            e.id, e.host_id, e.host_name, e.host_avatar,
            e.title, e.description, e.category, e.location, e.start_date, e.end_date,
            e.status, e.max_members, e.approval_required, e.private_message, e.linked_trip_id,
            e.trip_snapshot, e.snapshot_updated_at,
            e.like_count, e.comment_count, e.created_at, e.created_by, e.updated_at, e.updated_by,
            (SELECT COUNT(*) FROM group_event_applications WHERE event_id = e.id AND status = 'approved') as application_count,
            EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = e.id AND user_id = $2) as is_liked,
            (SELECT id FROM group_event_applications WHERE event_id = e.id AND user_id = $2 ORDER BY created_at DESC LIMIT 1) as my_application_id,
            (SELECT status FROM group_event_applications WHERE event_id = e.id AND user_id = $2 ORDER BY created_at DESC LIMIT 1) as my_application_status,
            (SELECT rejection_reason FROM group_event_applications WHERE event_id = e.id AND user_id = $2 ORDER BY created_at DESC LIMIT 1) as my_application_reason
        FROM group_events e
        WHERE e.id = $1
    `
	event := &GroupEvent{}
	var userIDArg any = userID
	if userID == "" {
		userIDArg = nil
	}

	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, id, userIDArg).Scan(
		&event.ID, &event.HostID, &event.HostName, &event.HostAvatar,
		&event.Title, &event.Description, &event.Category, &event.Location, &event.StartDate, &event.EndDate,
		&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
		&event.TripSnapshot, &event.SnapshotUpdatedAt,
		&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
		&event.ApplicationCount, &event.IsLiked, &event.MyApplicationID, &event.MyApplicationStatus, &event.MyApplicationReason,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get group event %s: %w", id, err)
	}
	return event, nil
}

func (r *groupEventRepository) ListEvents(ctx context.Context, status *string, category *Category, hostID *string, page int, limit int, search string, userID string) ([]*GroupEvent, int, bool, error) {
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
		whereClause += fmt.Sprintf(" AND e.status = $%d", len(args))
	}
	if category != nil {
		args = append(args, *category)
		whereClause += fmt.Sprintf(" AND e.category = $%d", len(args))
	}
	if hostID != nil {
		args = append(args, *hostID)
		whereClause += fmt.Sprintf(" AND e.host_id = $%d", len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		whereClause += fmt.Sprintf(" AND e.title ILIKE $%d", len(args))
	}

	db := database.GetQuerier(ctx, r.db)
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM group_events e %s", whereClause)
	if err := db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, false, fmt.Errorf("count group events: %w", err)
	}

	var userIDArg any = userID
	if userID == "" {
		userIDArg = nil
	}

	dataArgs := append(args, userIDArg, limit, (page-1)*limit)
	mainQuery := fmt.Sprintf(`
        SELECT
            e.id, e.host_id, e.host_name, e.host_avatar,
            e.title, e.description, e.category, e.location, e.start_date, e.end_date,
            e.status, e.max_members, e.approval_required, e.private_message, e.linked_trip_id,
            e.trip_snapshot, e.snapshot_updated_at,
            e.like_count, e.comment_count, e.created_at, e.created_by, e.updated_at, e.updated_by,
            (SELECT COUNT(*) FROM group_event_applications WHERE event_id = e.id AND status = 'approved') as application_count,
            EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = e.id AND user_id = $%d) as is_liked,
            (SELECT id FROM group_event_applications WHERE event_id = e.id AND user_id = $%d ORDER BY created_at DESC LIMIT 1) as my_application_id,
            (SELECT status FROM group_event_applications WHERE event_id = e.id AND user_id = $%d ORDER BY created_at DESC LIMIT 1) as my_application_status,
            (SELECT rejection_reason FROM group_event_applications WHERE event_id = e.id AND user_id = $%d ORDER BY created_at DESC LIMIT 1) as my_application_reason
        FROM group_events e
        %s
        ORDER BY e.created_at DESC, e.id DESC
        LIMIT $%d OFFSET $%d
    `, len(args)+1, len(args)+1, len(args)+1, len(args)+1, whereClause, len(args)+2, len(args)+3)

	rows, err := db.Query(ctx, mainQuery, dataArgs...)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query group events: %w", err)
	}
	defer rows.Close()

	var events []*GroupEvent
	for rows.Next() {
		event := &GroupEvent{}
		err := rows.Scan(
			&event.ID, &event.HostID, &event.HostName, &event.HostAvatar,
			&event.Title, &event.Description, &event.Category, &event.Location, &event.StartDate, &event.EndDate,
			&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
			&event.TripSnapshot, &event.SnapshotUpdatedAt,
			&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
			&event.ApplicationCount, &event.IsLiked, &event.MyApplicationID, &event.MyApplicationStatus, &event.MyApplicationReason,
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

func (r *groupEventRepository) ListEventsByUser(ctx context.Context, userID string, listType string, page int, limit int) ([]*GroupEvent, int, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}

	whereClause := ""
	switch listType {
	case "host":
		whereClause = "WHERE e.host_id = $1"
	case "apply":
		whereClause = "WHERE EXISTS (SELECT 1 FROM group_event_applications WHERE event_id = e.id AND user_id = $1)"
	case "like":
		whereClause = "WHERE EXISTS (SELECT 1 FROM group_event_likes WHERE event_id = e.id AND user_id = $1)"
	default:
		// Default to host if unknown
		whereClause = "WHERE e.host_id = $1"
	}

	db := database.GetQuerier(ctx, r.db)
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM group_events e %s", whereClause)
	if err := db.QueryRow(ctx, countQuery, userID).Scan(&total); err != nil {
		return nil, 0, false, fmt.Errorf("count my group events: %w", err)
	}

	mainQuery := fmt.Sprintf(`
        SELECT
            e.id, e.host_id, e.host_name, e.host_avatar,
            e.title, e.description, e.category, e.location, e.start_date, e.end_date,
            e.status, e.max_members, e.approval_required, e.private_message, e.linked_trip_id,
            e.trip_snapshot, e.snapshot_updated_at,
            e.like_count, e.comment_count, e.created_at, e.created_by, e.updated_at, e.updated_by,
            (SELECT COUNT(*) FROM group_event_applications WHERE event_id = e.id AND status = 'approved') as application_count,
            EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = e.id AND user_id = $1) as is_liked,
            (SELECT id FROM group_event_applications WHERE event_id = e.id AND user_id = $1 ORDER BY created_at DESC LIMIT 1) as my_application_id,
            (SELECT status FROM group_event_applications WHERE event_id = e.id AND user_id = $1 ORDER BY created_at DESC LIMIT 1) as my_application_status,
            (SELECT rejection_reason FROM group_event_applications WHERE event_id = e.id AND user_id = $1 ORDER BY created_at DESC LIMIT 1) as my_application_reason
        FROM group_events e
        %s
        ORDER BY e.created_at DESC, e.id DESC
        LIMIT $2 OFFSET $3
    `, whereClause)

	rows, err := db.Query(ctx, mainQuery, userID, limit, (page-1)*limit)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query my group events: %w", err)
	}
	defer rows.Close()

	var events []*GroupEvent
	for rows.Next() {
		event := &GroupEvent{}
		err := rows.Scan(
			&event.ID, &event.HostID, &event.HostName, &event.HostAvatar,
			&event.Title, &event.Description, &event.Category, &event.Location, &event.StartDate, &event.EndDate,
			&event.Status, &event.MaxMembers, &event.ApprovalRequired, &event.PrivateMessage, &event.LinkedTripID,
			&event.TripSnapshot, &event.SnapshotUpdatedAt,
			&event.LikeCount, &event.CommentCount, &event.CreatedAt, &event.CreatedBy, &event.UpdatedAt, &event.UpdatedBy,
			&event.ApplicationCount, &event.IsLiked, &event.MyApplicationID, &event.MyApplicationStatus, &event.MyApplicationReason,
		)
		if err != nil {
			return nil, 0, false, fmt.Errorf("scan my group event row: %w", err)
		}
		events = append(events, event)
	}
	return events, total, page*limit < total, nil
}

func (r *groupEventRepository) UpdateEvent(ctx context.Context, event *GroupEvent) error {
	query := `
        UPDATE group_events
        SET title = $1, description = $2, category = $3, location = $4, start_date = $5, end_date = $6,
            max_members = $7, approval_required = $8, private_message = $9, linked_trip_id = $10,
            updated_at = NOW(), updated_by = $11
        WHERE id = $12
        RETURNING updated_at
    `
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		event.Title, event.Description, event.Category, event.Location, event.StartDate, event.EndDate,
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
            event_id, user_id, status, message, created_by, updated_by
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, created_at, updated_at
    `
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query,
		app.EventID, app.UserID, app.Status, app.Message, app.CreatedBy, app.UpdatedBy,
	).Scan(&app.ID, &app.CreatedAt, &app.UpdatedAt)
	if err != nil {
		return fmt.Errorf("apply to group event %s by user %s: %w", app.EventID, app.UserID, err)
	}
	return nil
}

func (r *groupEventRepository) ListApplications(ctx context.Context, eventID string) ([]*GroupEventApplication, error) {
	query := `
        SELECT
            a.id, a.event_id, a.user_id, u.display_name as user_name, u.avatar as user_avatar,
            a.status, a.message, a.rejection_reason, a.created_at, a.created_by, a.updated_at, a.updated_by
        FROM group_event_applications a
        JOIN users u ON a.user_id = u.id
        WHERE a.event_id = $1
        ORDER BY a.created_at ASC
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
			&app.ID, &app.EventID, &app.UserID, &app.UserName, &app.UserAvatar,
			&app.Status, &app.Message, &app.RejectionReason,
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

func (r *groupEventRepository) UpdateApplicationStatus(ctx context.Context, id, status, rejectionReason, updatedBy string) error {
	query := `
        UPDATE group_event_applications
        SET status = $1, rejection_reason = $2, updated_at = NOW(), updated_by = $3
        WHERE id = $4
    `
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, status, rejectionReason, updatedBy, id)
	if err != nil {
		return fmt.Errorf("update application status for %s: %w", id, err)
	}
	return nil
}

func (r *groupEventRepository) GetPendingApplicationByEventAndUser(ctx context.Context, eventID, userID string) (*GroupEventApplication, error) {
	query := `
        SELECT id, event_id, user_id, status, message, rejection_reason, created_at, created_by, updated_at, updated_by
        FROM group_event_applications
        WHERE event_id = $1 AND user_id = $2 AND status = 'pending'
        LIMIT 1
    `
	app := &GroupEventApplication{}
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, eventID, userID).Scan(
		&app.ID, &app.EventID, &app.UserID, &app.Status, &app.Message, &app.RejectionReason,
		&app.CreatedAt, &app.CreatedBy, &app.UpdatedAt, &app.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get pending application for event %s, user %s: %w", eventID, userID, err)
	}
	return app, nil
}

func (r *groupEventRepository) GetApplicationByID(ctx context.Context, id string) (*GroupEventApplication, error) {
	query := `
        SELECT id, event_id, user_id, status, message, rejection_reason, created_at, created_by, updated_at, updated_by
        FROM group_event_applications
        WHERE id = $1
    `
	app := &GroupEventApplication{}
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, id).Scan(
		&app.ID, &app.EventID, &app.UserID, &app.Status, &app.Message, &app.RejectionReason,
		&app.CreatedAt, &app.CreatedBy, &app.UpdatedAt, &app.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get application %s: %w", id, err)
	}
	return app, nil
}

func (r *groupEventRepository) DeleteApplication(ctx context.Context, id string) error {
	query := `DELETE FROM group_event_applications WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("delete application %s: %w", id, err)
	}
	return nil
}

func (r *groupEventRepository) GetCommentByID(ctx context.Context, id string) (*GroupEventComment, error) {
	query := `
		SELECT id, event_id, user_id, content, created_at, created_by, updated_at, updated_by
		FROM group_event_comments
		WHERE id = $1
	`
	c := &GroupEventComment{}
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.EventID, &c.UserID, &c.Content,
		&c.CreatedAt, &c.CreatedBy, &c.UpdatedAt, &c.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get comment %s: %w", id, err)
	}
	return c, nil
}

func (r *groupEventRepository) AddComment(ctx context.Context, comment *GroupEventComment) error {
	db := database.GetQuerier(ctx, r.db)

	query := `
        INSERT INTO group_event_comments (
            event_id, user_id, content, created_by, updated_by
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING id, created_at, updated_at
    `
	err := db.QueryRow(ctx, query,
		comment.EventID, comment.UserID, comment.Content, comment.CreatedBy, comment.UpdatedBy,
	).Scan(&comment.ID, &comment.CreatedAt, &comment.UpdatedAt)
	if err != nil {
		return fmt.Errorf("insert comment to event %s: %w", comment.EventID, err)
	}

	_, err = db.Exec(ctx, "UPDATE group_events SET comment_count = comment_count + 1 WHERE id = $1", comment.EventID)
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

	var eventID string
	err := db.QueryRow(ctx, "DELETE FROM group_event_comments WHERE id = $1 AND user_id = $2 RETURNING event_id", commentID, userID).Scan(&eventID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("comment %s not found or unauthorized", commentID)
		}
		return fmt.Errorf("delete comment %s: %w", commentID, err)
	}

	_, err = db.Exec(ctx, "UPDATE group_events SET comment_count = comment_count - 1 WHERE id = $1", eventID)
	if err != nil {
		return fmt.Errorf("decrement comment count for event %s: %w", eventID, err)
	}

	return nil
}

func (r *groupEventRepository) ToggleLike(ctx context.Context, eventID, userID string) (bool, error) {
	db := database.GetQuerier(ctx, r.db)

	var exists bool
	err := db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM group_event_likes WHERE event_id = $1 AND user_id = $2)", eventID, userID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check existing like for event %s, user %s: %w", eventID, userID, err)
	}

	var isLiked bool
	if exists {
		_, err = db.Exec(ctx, "DELETE FROM group_event_likes WHERE event_id = $1 AND user_id = $2", eventID, userID)
		if err != nil {
			return false, fmt.Errorf("delete like for event %s, user %s: %w", eventID, userID, err)
		}
		_, err = db.Exec(ctx, "UPDATE group_events SET like_count = like_count - 1 WHERE id = $1", eventID)
		if err != nil {
			return false, fmt.Errorf("decrement like count for event %s: %w", eventID, err)
		}
		isLiked = false
	} else {
		_, err = db.Exec(ctx, "INSERT INTO group_event_likes (event_id, user_id, created_by) VALUES ($1, $2, $2)", eventID, userID)
		if err != nil {
			return false, fmt.Errorf("insert like for event %s, user %s: %w", eventID, userID, err)
		}
		_, err = db.Exec(ctx, "UPDATE group_events SET like_count = like_count + 1 WHERE id = $1", eventID)
		if err != nil {
			return false, fmt.Errorf("increment like count for event %s: %w", eventID, err)
		}
		isLiked = true
	}

	return isLiked, nil
}

func (r *groupEventRepository) UpdateTripLink(ctx context.Context, eventID string, tripID *string, userID string) error {
	query := `
        UPDATE group_events
        SET linked_trip_id = $1, updated_at = NOW(), updated_by = $2
        WHERE id = $3
    `
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, tripID, userID, eventID)
	if err != nil {
		return fmt.Errorf("update group event trip link %s: %w", eventID, err)
	}
	return nil
}

func (r *groupEventRepository) UpdateTripSnapshot(ctx context.Context, eventID string, snapshot *TripSnapshot, userID string) error {
	query := `
        UPDATE group_events
        SET trip_snapshot = $1, snapshot_updated_at = NOW(), updated_at = NOW(), updated_by = $2
        WHERE id = $3
    `
	db := database.GetQuerier(ctx, r.db)
	_, err := db.Exec(ctx, query, snapshot, userID, eventID)
	if err != nil {
		return fmt.Errorf("update group event trip snapshot %s: %w", eventID, err)
	}
	return nil
}
