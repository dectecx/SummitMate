package sync

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Result statuses returned for each pushed operation.
const (
	StatusApplied   = "applied"
	StatusGone      = "gone"
	StatusForbidden = "forbidden"
	StatusInvalid   = "invalid"
)

const (
	defaultPullLimit = 200
	maxPullLimit     = 500
	MaxPushOps       = 100
)

// Op is one client operation.
type Op struct {
	OpID     uuid.UUID
	Entity   string
	EntityID uuid.UUID
	Delete   bool
	Patch    map[string]any
}

// Result is the outcome of one Op.
type Result struct {
	OpID    uuid.UUID      `json:"op_id"`
	Status  string         `json:"status"`
	Message string         `json:"message,omitempty"`
	Row     map[string]any `json:"row,omitempty"`
}

// Changes is one page of pulled rows.
type Changes struct {
	ServerTime time.Time
	NextSince  time.Time
	HasMore    bool
	Rows       map[string][]map[string]any
}

// Service implements pull and push.
type Service struct{ pool *pgxpool.Pool }

func NewService(pool *pgxpool.Pool) *Service { return &Service{pool: pool} }

// ---------------------------------------------------------------- pull

const activeTrips = `(SELECT m.trip_id FROM trip_members m JOIN trips t ON t.id = m.trip_id
	WHERE m.user_id = $1 AND m.deleted_at IS NULL AND t.deleted_at IS NULL)`

// pullQueries return rows as (updated_at, jsonb) ordered by updated_at.
// $1 = user, $2 = since, $3 = limit.
var pullQueries = map[string]string{
	// Includes deleted trips so that members receive the tombstone.
	"trips": `SELECT updated_at, to_jsonb(t) FROM trips t
		WHERE t.id IN (SELECT trip_id FROM trip_members WHERE user_id = $1 AND deleted_at IS NULL)
		  AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
	// A member always receives their own membership rows, including their removal tombstone.
	"trip_members": `SELECT m.updated_at, to_jsonb(m) || jsonb_build_object('display_name', u.display_name, 'avatar', u.avatar)
		FROM trip_members m JOIN users u ON u.id = m.user_id
		WHERE (m.trip_id IN ` + activeTrips + ` OR m.user_id = $1) AND m.updated_at > $2
		ORDER BY m.updated_at LIMIT $3`,
	"itinerary_items": `SELECT i.updated_at, to_jsonb(i) FROM itinerary_items i
		WHERE i.trip_id IN ` + activeTrips + ` AND i.updated_at > $2 ORDER BY i.updated_at LIMIT $3`,
	"meal_plan_days": `SELECT updated_at, to_jsonb(t) FROM meal_plan_days t
		WHERE t.user_id = $1 AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
	"gear_items": `SELECT updated_at, to_jsonb(t) FROM gear_items t
		WHERE t.user_id = $1 AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
	"meal_items": `SELECT updated_at, to_jsonb(t) FROM meal_items t
		WHERE t.user_id = $1 AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
	"library_items": `SELECT updated_at, to_jsonb(t) FROM library_items t
		WHERE t.user_id = $1 AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
	"templates": `SELECT updated_at, to_jsonb(t) FROM templates t
		WHERE t.user_id = $1 AND t.updated_at > $2 ORDER BY t.updated_at LIMIT $3`,
}

// Pull returns rows changed after since (all rows when since is nil).
func (s *Service) Pull(ctx context.Context, userID uuid.UUID, since *time.Time, limit int) (Changes, error) {
	if limit <= 0 {
		limit = defaultPullLimit
	}
	if limit > maxPullLimit {
		limit = maxPullLimit
	}
	floor := time.Date(1970, 1, 1, 0, 0, 0, 0, time.UTC)
	if since != nil {
		floor = *since
	}
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
	if err != nil {
		return Changes{}, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // read-only

	var serverTime time.Time
	if err := tx.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&serverTime); err != nil {
		return Changes{}, err
	}
	out := Changes{ServerTime: serverTime, Rows: map[string][]map[string]any{}}
	var cut *time.Time // earliest "last row" among truncated entities
	for _, name := range pullOrder {
		rows, err := tx.Query(ctx, pullQueries[name], userID, floor, limit)
		if err != nil {
			return Changes{}, fmt.Errorf("pull %s: %w", name, err)
		}
		var list []map[string]any
		var last time.Time
		for rows.Next() {
			var ts time.Time
			var raw []byte
			if err := rows.Scan(&ts, &raw); err != nil {
				rows.Close()
				return Changes{}, err
			}
			var m map[string]any
			if err := json.Unmarshal(raw, &m); err != nil {
				rows.Close()
				return Changes{}, err
			}
			list = append(list, m)
			last = ts
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return Changes{}, err
		}
		if len(list) > 0 {
			out.Rows[name] = list
		}
		if len(list) == limit {
			out.HasMore = true
			if cut == nil || last.Before(*cut) {
				l := last
				cut = &l
			}
		}
	}
	out.NextSince = serverTime
	if cut != nil {
		out.NextSince = *cut
	}
	return out, nil
}

// ---------------------------------------------------------------- push

// Push applies ops in order inside one transaction. Each op is isolated by a savepoint
// so a rejected op does not affect the others. Re-sent op IDs return their original result.
func (s *Service) Push(ctx context.Context, userID uuid.UUID, ops []Op) ([]Result, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // no-op after commit

	results := make([]Result, 0, len(ops))
	for _, op := range ops {
		if prev, ok, err := lookupProcessed(ctx, tx, userID, op.OpID); err != nil {
			return nil, err
		} else if ok {
			results = append(results, prev)
			continue
		}
		sp, err := tx.Begin(ctx)
		if err != nil {
			return nil, err
		}
		res, err := applyOp(ctx, sp, userID, op)
		if err != nil {
			_ = sp.Rollback(ctx)
			if msg, ok := dataError(err); ok {
				res = Result{OpID: op.OpID, Status: StatusInvalid, Message: msg}
			} else {
				return nil, err
			}
		} else if res.Status == StatusApplied || res.Status == StatusGone {
			if err := sp.Commit(ctx); err != nil {
				return nil, err
			}
		} else {
			_ = sp.Rollback(ctx)
		}
		res.OpID = op.OpID
		if err := saveProcessed(ctx, tx, userID, res); err != nil {
			return nil, err
		}
		results = append(results, res)
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return results, nil
}

// dataError reports whether err is a constraint or data-format violation caused by client data.
func dataError(err error) (string, bool) {
	var pe *pgconn.PgError
	if errors.As(err, &pe) && (strings.HasPrefix(pe.Code, "23") || strings.HasPrefix(pe.Code, "22")) {
		return "rejected by database: " + pe.Message, true
	}
	return "", false
}

func lookupProcessed(ctx context.Context, tx pgx.Tx, userID, opID uuid.UUID) (Result, bool, error) {
	var owner uuid.UUID
	var raw []byte
	err := tx.QueryRow(ctx, `SELECT user_id, result FROM processed_ops WHERE op_id = $1`, opID).Scan(&owner, &raw)
	if errors.Is(err, pgx.ErrNoRows) {
		return Result{}, false, nil
	}
	if err != nil {
		return Result{}, false, err
	}
	if owner != userID {
		return Result{OpID: opID, Status: StatusInvalid, Message: "op_id already used"}, true, nil
	}
	var r Result
	if err := json.Unmarshal(raw, &r); err != nil {
		return Result{}, false, err
	}
	return r, true, nil
}

func saveProcessed(ctx context.Context, tx pgx.Tx, userID uuid.UUID, r Result) error {
	raw, err := json.Marshal(r)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `INSERT INTO processed_ops (op_id, user_id, result) VALUES ($1, $2, $3)
		ON CONFLICT (op_id) DO NOTHING`, r.OpID, userID, raw)
	return err
}

func invalid(msg string) (Result, error)   { return Result{Status: StatusInvalid, Message: msg}, nil }
func forbidden(msg string) (Result, error) { return Result{Status: StatusForbidden, Message: msg}, nil }

// tripRole returns the caller's role on a live trip, or "" if not an active member.
func tripRole(ctx context.Context, tx pgx.Tx, tripID, userID uuid.UUID) (string, error) {
	var role string
	err := tx.QueryRow(ctx, `SELECT m.role FROM trip_members m JOIN trips t ON t.id = m.trip_id
		WHERE m.trip_id = $1 AND m.user_id = $2 AND m.deleted_at IS NULL AND t.deleted_at IS NULL`, tripID, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", nil
	}
	return role, err
}

func isEditor(role string) bool { return role == "owner" || role == "guide" }

// existing holds the fields of an already stored row that permission checks need.
type existing struct {
	found   bool
	deleted bool
	tripID  uuid.UUID
	userID  uuid.UUID // personal rows: the owner; trip_members: the member
	role    string    // trip_members only
}

func loadExisting(ctx context.Context, tx pgx.Tx, e entity, id uuid.UUID) (existing, error) {
	var ex existing
	var deletedAt *time.Time
	var err error
	switch e.access {
	case accessRoot:
		err = tx.QueryRow(ctx, `SELECT id, deleted_at FROM trips WHERE id = $1 FOR UPDATE`, id).Scan(&ex.tripID, &deletedAt)
	case accessMember:
		err = tx.QueryRow(ctx, `SELECT trip_id, user_id, role, deleted_at FROM trip_members WHERE id = $1 FOR UPDATE`, id).
			Scan(&ex.tripID, &ex.userID, &ex.role, &deletedAt)
	case accessShared:
		err = tx.QueryRow(ctx, `SELECT trip_id, deleted_at FROM `+e.table+` WHERE id = $1 FOR UPDATE`, id).Scan(&ex.tripID, &deletedAt)
	case accessPersonal:
		err = tx.QueryRow(ctx, `SELECT trip_id, user_id, deleted_at FROM `+e.table+` WHERE id = $1 FOR UPDATE`, id).
			Scan(&ex.tripID, &ex.userID, &deletedAt)
	case accessOwner:
		err = tx.QueryRow(ctx, `SELECT user_id, deleted_at FROM `+e.table+` WHERE id = $1 FOR UPDATE`, id).
			Scan(&ex.userID, &deletedAt)
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return existing{}, nil
	}
	if err != nil {
		return existing{}, err
	}
	ex.found = true
	ex.deleted = deletedAt != nil
	return ex, nil
}

func applyOp(ctx context.Context, tx pgx.Tx, userID uuid.UUID, op Op) (Result, error) {
	e, ok := entities[op.Entity]
	if !ok {
		return invalid("unknown entity")
	}
	ex, err := loadExisting(ctx, tx, e, op.EntityID)
	if err != nil {
		return Result{}, err
	}
	if op.Delete {
		return applyDelete(ctx, tx, userID, e, op, ex)
	}
	return applyUpsert(ctx, tx, userID, e, op, ex)
}

// canWrite checks permission to modify an existing row.
func canWrite(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, ex existing, forDelete bool) (bool, error) {
	if e.access == accessOwner {
		return ex.userID == userID, nil
	}
	role, err := tripRole(ctx, tx, ex.tripID, userID)
	if err != nil {
		return false, err
	}
	switch e.access {
	case accessRoot:
		if forDelete {
			return role == "owner", nil
		}
		return isEditor(role), nil
	case accessShared:
		return isEditor(role), nil
	case accessPersonal:
		return role != "" && ex.userID == userID, nil
	case accessMember:
		if ex.role == "owner" {
			return false, nil // the owner's membership is never edited or removed through sync
		}
		if forDelete && ex.userID == userID {
			return true, nil // leaving a trip
		}
		return isEditor(role), nil
	}
	return false, nil
}

func applyDelete(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, op Op, ex existing) (Result, error) {
	if !ex.found || ex.deleted {
		return Result{Status: StatusGone}, nil
	}
	ok, err := canWrite(ctx, tx, userID, e, ex, true)
	if err != nil {
		return Result{}, err
	}
	if !ok {
		return forbidden("not allowed to delete this item")
	}
	if _, err := tx.Exec(ctx, `UPDATE `+e.table+` SET deleted_at = clock_timestamp(), updated_by = $2 WHERE id = $1`, op.EntityID, userID); err != nil {
		return Result{}, err
	}
	row, err := rowJSON(ctx, tx, e, op.EntityID)
	return Result{Status: StatusApplied, Row: row}, err
}

func applyUpsert(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, op Op, ex existing) (Result, error) {
	// Revive: re-inviting a removed member reuses the same deterministic row.
	revive := e.access == accessMember && ex.found && ex.deleted
	if ex.found && ex.deleted && !revive {
		return Result{Status: StatusGone}, nil
	}

	vals := map[string]any{}
	for name, raw := range op.Patch {
		c, ok := e.cols[name]
		if !ok {
			return invalid("unknown field: " + name)
		}
		if ex.found && c.immutable {
			continue
		}
		v, err := coerce(c, raw)
		if err != nil {
			return invalid(name + " " + err.Error())
		}
		vals[name] = v
	}
	if e.validate != nil {
		if msg := e.validate(vals); msg != "" {
			return invalid(msg)
		}
	}

	if ex.found {
		return updateRow(ctx, tx, userID, e, op, ex, vals, revive)
	}
	return insertRow(ctx, tx, userID, e, op, vals)
}

func updateRow(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, op Op, ex existing, vals map[string]any, revive bool) (Result, error) {
	if e.access == accessMember {
		if role, ok := vals["role"].(string); ok && role != "guide" && role != "member" {
			return invalid("role must be guide or member")
		}
		if revive && ex.role == "owner" {
			return forbidden("not allowed")
		}
	}
	ok, err := canWrite(ctx, tx, userID, e, ex, false)
	if err != nil {
		return Result{}, err
	}
	if !ok {
		return forbidden("not allowed to modify this item")
	}
	if e.access == accessMember && !revive && len(vals) == 0 {
		row, err := rowJSON(ctx, tx, e, op.EntityID)
		return Result{Status: StatusApplied, Row: row}, err
	}
	sets, args := buildSets(vals, 3)
	if revive {
		sets = append(sets, "deleted_at = NULL")
	}
	sets = append(sets, "updated_by = $2")
	args = append([]any{op.EntityID, userID}, args...)
	if _, err := tx.Exec(ctx, `UPDATE `+e.table+` SET `+strings.Join(sets, ", ")+` WHERE id = $1`, args...); err != nil {
		return Result{}, err
	}
	row, err := rowJSON(ctx, tx, e, op.EntityID)
	return Result{Status: StatusApplied, Row: row}, err
}

// buildSets returns "col = $n" fragments (sorted for stable SQL) and their args, numbering from first.
func buildSets(vals map[string]any, first int) ([]string, []any) {
	names := make([]string, 0, len(vals))
	for n := range vals {
		names = append(names, n)
	}
	sort.Strings(names)
	sets := make([]string, 0, len(names)+2)
	args := make([]any, 0, len(names))
	for i, n := range names {
		sets = append(sets, fmt.Sprintf("%s = $%d", n, first+i))
		args = append(args, vals[n])
	}
	return sets, args
}

func insertRow(ctx context.Context, tx pgx.Tx, userID uuid.UUID, e entity, op Op, vals map[string]any) (Result, error) {
	for name, c := range e.cols {
		if _, ok := vals[name]; c.required && !ok {
			return invalid("missing required field: " + name)
		}
	}
	forced := map[string]any{"id": op.EntityID, "created_by": userID, "updated_by": userID}

	var tripID uuid.UUID
	if e.access == accessOwner {
		forced["user_id"] = userID
	} else if e.access != accessRoot {
		tripID = vals["trip_id"].(uuid.UUID)
		role, err := tripRole(ctx, tx, tripID, userID)
		if err != nil {
			return Result{}, err
		}
		switch e.access {
		case accessShared, accessMember:
			if !isEditor(role) {
				return forbidden("not allowed to add to this trip")
			}
		case accessPersonal:
			if role == "" {
				return forbidden("not a member of this trip")
			}
			forced["user_id"] = userID
		}
	}

	switch e.access {
	case accessRoot:
		forced["owner_id"] = userID
	case accessMember:
		target := vals["user_id"].(uuid.UUID)
		if op.EntityID != MemberID(tripID, target) {
			return invalid("trip_members id must be uuidv5(trip_id:user_id)")
		}
		if role, ok := vals["role"].(string); ok && role != "guide" && role != "member" {
			return invalid("role must be guide or member")
		}
		var active bool
		err := tx.QueryRow(ctx, `SELECT is_active AND is_verified FROM users WHERE id = $1`, target).Scan(&active)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && !active) {
			return invalid("user not found")
		}
		if err != nil {
			return Result{}, err
		}
	}
	if e.access == accessPersonal && op.Entity == "meal_items" {
		var one int
		err := tx.QueryRow(ctx, `SELECT 1 FROM meal_plan_days WHERE id = $1 AND trip_id = $2 AND user_id = $3 AND deleted_at IS NULL`,
			vals["meal_plan_day_id"], tripID, userID).Scan(&one)
		if errors.Is(err, pgx.ErrNoRows) {
			return invalid("meal_plan_day_id does not exist in this trip")
		}
		if err != nil {
			return Result{}, err
		}
	}

	cols, args := []string{}, []any{}
	for _, m := range []map[string]any{forced, vals} {
		names := make([]string, 0, len(m))
		for n := range m {
			names = append(names, n)
		}
		sort.Strings(names)
		for _, n := range names {
			cols = append(cols, n)
			args = append(args, m[n])
		}
	}
	ph := make([]string, len(cols))
	for i := range cols {
		ph[i] = fmt.Sprintf("$%d", i+1)
	}
	if _, err := tx.Exec(ctx, `INSERT INTO `+e.table+` (`+strings.Join(cols, ", ")+`) VALUES (`+strings.Join(ph, ", ")+`)`, args...); err != nil {
		return Result{}, err
	}
	if e.access == accessRoot {
		// The creator becomes the owner. Clients do not push this row.
		_, err := tx.Exec(ctx, `INSERT INTO trip_members (id, trip_id, user_id, role, created_by, updated_by)
			VALUES ($1, $2, $3, 'owner', $3, $3)`, MemberID(op.EntityID, userID), op.EntityID, userID)
		if err != nil {
			return Result{}, err
		}
	}
	row, err := rowJSON(ctx, tx, e, op.EntityID)
	return Result{Status: StatusApplied, Row: row}, err
}

func rowJSON(ctx context.Context, tx pgx.Tx, e entity, id uuid.UUID) (map[string]any, error) {
	q := `SELECT to_jsonb(t) FROM ` + e.table + ` t WHERE t.id = $1`
	if e.access == accessMember {
		q = `SELECT to_jsonb(m) || jsonb_build_object('display_name', u.display_name, 'avatar', u.avatar)
			FROM trip_members m JOIN users u ON u.id = m.user_id WHERE m.id = $1`
	}
	var raw []byte
	if err := tx.QueryRow(ctx, q, id).Scan(&raw); err != nil {
		return nil, err
	}
	var m map[string]any
	return m, json.Unmarshal(raw, &m)
}
