package groupevents

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound is returned by the repository when a row does not exist.
var ErrNotFound = errors.New("not found")

// Repository is the storage port. Reads that are not part of a rule check run outside a transaction.
type Repository interface {
	// WithTx runs fn in one transaction; an error rolls everything back.
	WithTx(ctx context.Context, fn func(Tx) error) error
	// Get returns one live event with counts and the viewer's fields (viewer may be nil).
	Get(ctx context.Context, id uuid.UUID, viewer *uuid.UUID) (Event, error)
	List(ctx context.Context, q ListQuery) ([]Event, error)
	ListApplications(ctx context.Context, eventID uuid.UUID, statuses []string) ([]Application, error)
	ListComments(ctx context.Context, eventID uuid.UUID, limit int, after *Cursor) ([]Comment, error)
	GetComment(ctx context.Context, id uuid.UUID) (Comment, error)
	CreateComment(ctx context.Context, c Comment) (Comment, error)
	DeleteComment(ctx context.Context, id uuid.UUID) error
	// CreateReport stores r unless the reporter already reported the target (then the old row, false).
	CreateReport(ctx context.Context, r Report) (Report, bool, error)
}

// Tx is the transactional part of the port.
type Tx interface {
	// LockEvent reads a live event FOR UPDATE (raw columns, no counts).
	LockEvent(ctx context.Context, id uuid.UUID) (Event, error)
	InsertEvent(ctx context.Context, e Event) error
	SaveEvent(ctx context.Context, e Event) error
	ApprovedCount(ctx context.Context, eventID uuid.UUID) (int, error)
	GetApplication(ctx context.Context, eventID, userID uuid.UUID) (Application, error)
	GetApplicationByID(ctx context.Context, eventID, appID uuid.UUID) (Application, error)
	// SaveApplication inserts a new application or restarts the user's old one (new status, message, created_at).
	SaveApplication(ctx context.Context, a Application) error
	SetApplicationStatus(ctx context.Context, appID uuid.UUID, status, reason string) error
	// IsTripOwner reports whether user is an active owner of a live trip.
	IsTripOwner(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
	// AddTripMember adds or revives user as a 'member' (an existing active member keeps their role).
	AddTripMember(ctx context.Context, tripID, userID, actor uuid.UUID) error
	// RemoveTripMember soft-deletes the membership, except for owners.
	RemoveTripMember(ctx context.Context, tripID, userID, actor uuid.UUID) error
}

// PgRepository is the PostgreSQL implementation.
type PgRepository struct{ pool *pgxpool.Pool }

func NewPgRepository(pool *pgxpool.Pool) *PgRepository { return &PgRepository{pool: pool} }

func (r *PgRepository) WithTx(ctx context.Context, fn func(Tx) error) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if err := fn(pgTx{tx}); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// likeEscaper escapes LIKE wildcards for use with ESCAPE '\'.
var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

const summaryCols = `e.id, e.host_id, e.title, e.category, e.location, e.start_date, e.end_date, e.max_members,
	ac.n, pc.n, cc.n, e.status, e.approval_required, u.display_name, u.avatar, e.created_at,
	COALESCE(ma.status, '')`

const detailCols = `, e.description, e.private_message, e.linked_trip_id, e.trip_snapshot, e.snapshot_updated_at,
	COALESCE(ma.rejection_reason, '')`

// eventFrom joins host, counts (computed per row, no N+1) and the viewer's application ($1).
const eventFrom = ` FROM group_events e
	JOIN users u ON u.id = e.host_id
	JOIN LATERAL (SELECT count(*) AS n FROM group_event_applications a WHERE a.event_id = e.id AND a.status = 'approved') ac ON TRUE
	JOIN LATERAL (SELECT count(*) AS n FROM group_event_applications a WHERE a.event_id = e.id AND a.status = 'pending' AND e.host_id = $1::uuid) pc ON TRUE
	JOIN LATERAL (SELECT count(*) AS n FROM group_event_comments c WHERE c.event_id = e.id AND c.deleted_at IS NULL) cc ON TRUE
	LEFT JOIN group_event_applications ma ON ma.event_id = e.id AND ma.user_id = $1::uuid`

func scanEvent(row pgx.Row, detail bool) (Event, error) {
	var e Event
	dst := []any{&e.ID, &e.HostID, &e.Title, &e.Category, &e.Location, &e.StartDate, &e.EndDate, &e.MaxMembers,
		&e.ApprovedCount, &e.PendingCount, &e.CommentCount, &e.Status, &e.ApprovalRequired, &e.HostName, &e.HostAvatar,
		&e.CreatedAt, &e.MyStatus}
	if detail {
		dst = append(dst, &e.Description, &e.PrivateMessage, &e.LinkedTripID, &e.TripSnapshot, &e.SnapshotAt, &e.MyRejection)
	}
	return e, row.Scan(dst...)
}

func viewerArg(v *uuid.UUID) any {
	if v == nil {
		return nil
	}
	return *v
}

func (r *PgRepository) Get(ctx context.Context, id uuid.UUID, viewer *uuid.UUID) (Event, error) {
	e, err := scanEvent(r.pool.QueryRow(ctx, `SELECT `+summaryCols+detailCols+eventFrom+
		` WHERE e.id = $2 AND e.deleted_at IS NULL`, viewerArg(viewer), id), true)
	if errors.Is(err, pgx.ErrNoRows) {
		return Event{}, ErrNotFound
	}
	return e, err
}

func (r *PgRepository) List(ctx context.Context, q ListQuery) ([]Event, error) {
	args := []any{viewerArg(q.Viewer)}
	arg := func(v any) string {
		args = append(args, v)
		return "$" + strconv.Itoa(len(args))
	}
	where := []string{"e.deleted_at IS NULL"}
	order := "e.created_at DESC, e.id DESC"
	switch q.Scope {
	case ScopeAll:
		where = append(where, "e.status <> 'cancelled'")
	case ScopeUpcoming:
		where = append(where, "e.status <> 'cancelled'", "e.start_date >= "+arg(q.Today)+"::date")
		order = "e.start_date ASC, e.id ASC"
	case ScopePopular:
		where = append(where, "e.status <> 'cancelled'")
		order = "ac.n DESC, e.created_at DESC, e.id DESC"
	case ScopeJoined:
		where = append(where, "ma.status IN ('pending', 'approved')")
	case ScopeHosting:
		where = append(where, "e.host_id = $1::uuid")
	}
	if q.Q != "" {
		p := arg("%" + likeEscaper.Replace(q.Q) + "%")
		where = append(where, `(e.title ILIKE `+p+` ESCAPE '\' OR e.location ILIKE `+p+` ESCAPE '\')`)
	}
	if q.After != nil {
		if q.Scope == ScopeUpcoming {
			where = append(where, "(e.start_date, e.id) > ("+arg(q.After.Time)+"::date, "+arg(q.After.ID)+")")
		} else {
			where = append(where, "(e.created_at, e.id) < ("+arg(q.After.Time)+", "+arg(q.After.ID)+")")
		}
	}
	sql := `SELECT ` + summaryCols + eventFrom + ` WHERE ` + strings.Join(where, " AND ") +
		` ORDER BY ` + order + ` LIMIT ` + arg(q.Limit)
	if q.Scope == ScopePopular && q.Offset > 0 {
		sql += ` OFFSET ` + arg(q.Offset)
	}
	rows, err := r.pool.Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Event
	for rows.Next() {
		e, err := scanEvent(rows, false)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func (r *PgRepository) ListApplications(ctx context.Context, eventID uuid.UUID, statuses []string) ([]Application, error) {
	rows, err := r.pool.Query(ctx, `SELECT a.id, a.event_id, a.user_id, u.display_name, u.avatar, a.status, a.message,
		a.rejection_reason, a.created_at
		FROM group_event_applications a JOIN users u ON u.id = a.user_id
		WHERE a.event_id = $1 AND a.status = ANY($2) ORDER BY a.created_at, a.id`, eventID, statuses)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Application
	for rows.Next() {
		var a Application
		if err := rows.Scan(&a.ID, &a.EventID, &a.UserID, &a.UserName, &a.UserAvatar, &a.Status, &a.Message,
			&a.RejectionReason, &a.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

func (r *PgRepository) ListComments(ctx context.Context, eventID uuid.UUID, limit int, after *Cursor) ([]Comment, error) {
	args := []any{eventID}
	where := "c.event_id = $1 AND c.deleted_at IS NULL"
	if after != nil {
		args = append(args, after.Time, after.ID)
		where += " AND (c.created_at, c.id) > ($2, $3)"
	}
	args = append(args, limit)
	rows, err := r.pool.Query(ctx, `SELECT c.id, c.event_id, c.user_id, u.display_name, u.avatar, c.body, c.created_at
		FROM group_event_comments c JOIN users u ON u.id = c.user_id WHERE `+where+
		` ORDER BY c.created_at, c.id LIMIT $`+strconv.Itoa(len(args)), args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Comment
	for rows.Next() {
		var c Comment
		if err := rows.Scan(&c.ID, &c.EventID, &c.UserID, &c.UserName, &c.UserAvatar, &c.Body, &c.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func (r *PgRepository) GetComment(ctx context.Context, id uuid.UUID) (Comment, error) {
	var c Comment
	err := r.pool.QueryRow(ctx, `SELECT c.id, c.event_id, c.user_id, u.display_name, u.avatar, c.body, c.created_at
		FROM group_event_comments c JOIN users u ON u.id = c.user_id WHERE c.id = $1 AND c.deleted_at IS NULL`, id).
		Scan(&c.ID, &c.EventID, &c.UserID, &c.UserName, &c.UserAvatar, &c.Body, &c.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Comment{}, ErrNotFound
	}
	return c, err
}

func (r *PgRepository) CreateComment(ctx context.Context, c Comment) (Comment, error) {
	err := r.pool.QueryRow(ctx, `WITH ins AS (
			INSERT INTO group_event_comments (id, event_id, user_id, body) VALUES ($1, $2, $3, $4) RETURNING created_at)
		SELECT ins.created_at, u.display_name, u.avatar FROM ins, users u WHERE u.id = $3`,
		c.ID, c.EventID, c.UserID, c.Body).Scan(&c.CreatedAt, &c.UserName, &c.UserAvatar)
	return c, err
}

func (r *PgRepository) DeleteComment(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `UPDATE group_event_comments SET deleted_at = clock_timestamp()
		WHERE id = $1 AND deleted_at IS NULL`, id)
	return err
}

func (r *PgRepository) CreateReport(ctx context.Context, rp Report) (Report, bool, error) {
	err := r.pool.QueryRow(ctx, `INSERT INTO reports (id, reporter_id, target_type, target_id, reason)
		VALUES ($1, $2, $3, $4, $5) ON CONFLICT (reporter_id, target_type, target_id) DO NOTHING
		RETURNING created_at`, rp.ID, rp.ReporterID, rp.TargetType, rp.TargetID, rp.Reason).Scan(&rp.CreatedAt)
	if err == nil {
		return rp, true, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return Report{}, false, err
	}
	err = r.pool.QueryRow(ctx, `SELECT id, reporter_id, target_type, target_id, reason, created_at FROM reports
		WHERE reporter_id = $1 AND target_type = $2 AND target_id = $3`, rp.ReporterID, rp.TargetType, rp.TargetID).
		Scan(&rp.ID, &rp.ReporterID, &rp.TargetType, &rp.TargetID, &rp.Reason, &rp.CreatedAt)
	return rp, false, err
}

type pgTx struct{ tx pgx.Tx }

func (t pgTx) LockEvent(ctx context.Context, id uuid.UUID) (Event, error) {
	var e Event
	err := t.tx.QueryRow(ctx, `SELECT id, host_id, title, description, category, location, start_date, end_date,
		max_members, approval_required, private_message, status, linked_trip_id, trip_snapshot, snapshot_updated_at,
		created_at FROM group_events WHERE id = $1 AND deleted_at IS NULL FOR UPDATE`, id).
		Scan(&e.ID, &e.HostID, &e.Title, &e.Description, &e.Category, &e.Location, &e.StartDate, &e.EndDate,
			&e.MaxMembers, &e.ApprovalRequired, &e.PrivateMessage, &e.Status, &e.LinkedTripID, &e.TripSnapshot,
			&e.SnapshotAt, &e.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Event{}, ErrNotFound
	}
	return e, err
}

func (t pgTx) InsertEvent(ctx context.Context, e Event) error {
	_, err := t.tx.Exec(ctx, `INSERT INTO group_events (id, host_id, title, description, category, location, start_date,
		end_date, max_members, approval_required, private_message, status, linked_trip_id, trip_snapshot, snapshot_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
		e.ID, e.HostID, e.Title, e.Description, e.Category, e.Location, e.StartDate, e.EndDate, e.MaxMembers,
		e.ApprovalRequired, e.PrivateMessage, e.Status, e.LinkedTripID, []byte(e.TripSnapshot), e.SnapshotAt)
	return err
}

func (t pgTx) SaveEvent(ctx context.Context, e Event) error {
	_, err := t.tx.Exec(ctx, `UPDATE group_events SET title = $2, description = $3, category = $4, location = $5,
		start_date = $6, end_date = $7, max_members = $8, approval_required = $9, private_message = $10, status = $11,
		linked_trip_id = $12, trip_snapshot = $13, snapshot_updated_at = $14 WHERE id = $1`,
		e.ID, e.Title, e.Description, e.Category, e.Location, e.StartDate, e.EndDate, e.MaxMembers, e.ApprovalRequired,
		e.PrivateMessage, e.Status, e.LinkedTripID, []byte(e.TripSnapshot), e.SnapshotAt)
	return err
}

func (t pgTx) ApprovedCount(ctx context.Context, eventID uuid.UUID) (int, error) {
	var n int
	err := t.tx.QueryRow(ctx, `SELECT count(*) FROM group_event_applications WHERE event_id = $1 AND status = 'approved'`,
		eventID).Scan(&n)
	return n, err
}

const appCols = `a.id, a.event_id, a.user_id, u.display_name, u.avatar, a.status, a.message, a.rejection_reason, a.created_at`
const appFrom = ` FROM group_event_applications a JOIN users u ON u.id = a.user_id`

func (t pgTx) getApp(ctx context.Context, where string, args ...any) (Application, error) {
	var a Application
	err := t.tx.QueryRow(ctx, `SELECT `+appCols+appFrom+` WHERE `+where, args...).
		Scan(&a.ID, &a.EventID, &a.UserID, &a.UserName, &a.UserAvatar, &a.Status, &a.Message, &a.RejectionReason, &a.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Application{}, ErrNotFound
	}
	return a, err
}

func (t pgTx) GetApplication(ctx context.Context, eventID, userID uuid.UUID) (Application, error) {
	return t.getApp(ctx, `a.event_id = $1 AND a.user_id = $2`, eventID, userID)
}

func (t pgTx) GetApplicationByID(ctx context.Context, eventID, appID uuid.UUID) (Application, error) {
	return t.getApp(ctx, `a.event_id = $1 AND a.id = $2`, eventID, appID)
}

func (t pgTx) SaveApplication(ctx context.Context, a Application) error {
	_, err := t.tx.Exec(ctx, `INSERT INTO group_event_applications (id, event_id, user_id, status, message)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (event_id, user_id) DO UPDATE SET status = EXCLUDED.status, message = EXCLUDED.message,
			rejection_reason = '', created_at = clock_timestamp()`,
		a.ID, a.EventID, a.UserID, a.Status, a.Message)
	return err
}

func (t pgTx) SetApplicationStatus(ctx context.Context, appID uuid.UUID, status, reason string) error {
	_, err := t.tx.Exec(ctx, `UPDATE group_event_applications SET status = $2, rejection_reason = $3 WHERE id = $1`,
		appID, status, reason)
	return err
}

func (t pgTx) IsTripOwner(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var ok bool
	err := t.tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM trip_members m JOIN trips t ON t.id = m.trip_id
		WHERE m.trip_id = $1 AND m.user_id = $2 AND m.role = 'owner' AND m.deleted_at IS NULL AND t.deleted_at IS NULL)`,
		tripID, userID).Scan(&ok)
	return ok, err
}
