package friends

import (
	"context"
	"errors"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound is returned by the repository when a row does not exist.
var ErrNotFound = errors.New("not found")

// Repository is the storage port.
type Repository interface {
	// WithTx runs fn in one transaction; an error rolls everything back.
	WithTx(ctx context.Context, fn func(Tx) error) error
	// List returns the friends and both request lists of user. Only active, verified people appear.
	List(ctx context.Context, user uuid.UUID) (Lists, error)
}

// Tx is the transactional part of the port.
type Tx interface {
	// LockPair serializes concurrent changes of one pair (order of a and b does not matter).
	LockPair(ctx context.Context, a, b uuid.UUID) error
	// UserAvailable reports whether the user exists, is active and verified.
	UserAvailable(ctx context.Context, id uuid.UUID) (bool, error)
	// GetByPair returns the row between a and b, or ErrNotFound.
	GetByPair(ctx context.Context, a, b uuid.UUID) (Friendship, error)
	// GetByID reads one row FOR UPDATE, or ErrNotFound.
	GetByID(ctx context.Context, id uuid.UUID) (Friendship, error)
	CountPendingOutgoing(ctx context.Context, user uuid.UUID) (int, error)
	Insert(ctx context.Context, f Friendship) error
	Accept(ctx context.Context, id uuid.UUID, at time.Time) error
	Delete(ctx context.Context, id uuid.UUID) error
	// DeleteAccepted removes the accepted row between a and b, if any.
	DeleteAccepted(ctx context.Context, a, b uuid.UUID) error
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

func (r *PgRepository) List(ctx context.Context, user uuid.UUID) (Lists, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT f.id, f.requester_id, f.status, f.created_at, f.responded_at, u.id, u.display_name, u.avatar
		FROM friendships f
		JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
		WHERE (f.requester_id = $1 OR f.addressee_id = $1) AND u.is_active AND u.is_verified
		ORDER BY f.created_at DESC, f.id DESC`, user)
	if err != nil {
		return Lists{}, err
	}
	defer rows.Close()
	out := Lists{Friends: []Friend{}, Incoming: []Request{}, Outgoing: []Request{}}
	for rows.Next() {
		var (
			id, requester uuid.UUID
			status        string
			created       time.Time
			responded     *time.Time
			p             Person
		)
		if err := rows.Scan(&id, &requester, &status, &created, &responded, &p.ID, &p.DisplayName, &p.Avatar); err != nil {
			return Lists{}, err
		}
		switch {
		case status == StatusAccepted:
			since := created
			if responded != nil {
				since = *responded
			}
			out.Friends = append(out.Friends, Friend{Person: p, Since: since})
		case requester == user:
			out.Outgoing = append(out.Outgoing, Request{ID: id, Person: p, CreatedAt: created})
		default:
			out.Incoming = append(out.Incoming, Request{ID: id, Person: p, CreatedAt: created})
		}
	}
	if err := rows.Err(); err != nil {
		return Lists{}, err
	}
	sortFriends(out.Friends)
	return out, nil
}

type pgTx struct{ tx pgx.Tx }

const cols = `id, requester_id, addressee_id, status, created_at, responded_at`

func scan(row pgx.Row) (Friendship, error) {
	var f Friendship
	err := row.Scan(&f.ID, &f.Requester, &f.Addressee, &f.Status, &f.CreatedAt, &f.RespondedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Friendship{}, ErrNotFound
	}
	return f, err
}

func (t pgTx) LockPair(ctx context.Context, a, b uuid.UUID) error {
	lo, hi := a.String(), b.String()
	if hi < lo {
		lo, hi = hi, lo
	}
	_, err := t.tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('friends:' || $1::text || $2::text, 0))`, lo, hi)
	return err
}

func (t pgTx) UserAvailable(ctx context.Context, id uuid.UUID) (bool, error) {
	var ok bool
	err := t.tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE id = $1 AND is_active AND is_verified)`, id).Scan(&ok)
	return ok, err
}

func (t pgTx) GetByPair(ctx context.Context, a, b uuid.UUID) (Friendship, error) {
	return scan(t.tx.QueryRow(ctx, `SELECT `+cols+` FROM friendships
		WHERE LEAST(requester_id, addressee_id) = LEAST($1::uuid, $2::uuid)
		  AND GREATEST(requester_id, addressee_id) = GREATEST($1::uuid, $2::uuid)`, a, b))
}

func (t pgTx) GetByID(ctx context.Context, id uuid.UUID) (Friendship, error) {
	return scan(t.tx.QueryRow(ctx, `SELECT `+cols+` FROM friendships WHERE id = $1 FOR UPDATE`, id))
}

func (t pgTx) CountPendingOutgoing(ctx context.Context, user uuid.UUID) (int, error) {
	var n int
	err := t.tx.QueryRow(ctx, `SELECT count(*) FROM friendships WHERE requester_id = $1 AND status = 'pending'`, user).Scan(&n)
	return n, err
}

func (t pgTx) Insert(ctx context.Context, f Friendship) error {
	_, err := t.tx.Exec(ctx, `INSERT INTO friendships (id, requester_id, addressee_id, status, created_at)
		VALUES ($1, $2, $3, $4, $5)`, f.ID, f.Requester, f.Addressee, f.Status, f.CreatedAt)
	return err
}

func (t pgTx) Accept(ctx context.Context, id uuid.UUID, at time.Time) error {
	_, err := t.tx.Exec(ctx, `UPDATE friendships SET status = 'accepted', responded_at = $2 WHERE id = $1`, id, at)
	return err
}

func (t pgTx) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := t.tx.Exec(ctx, `DELETE FROM friendships WHERE id = $1`, id)
	return err
}

func (t pgTx) DeleteAccepted(ctx context.Context, a, b uuid.UUID) error {
	_, err := t.tx.Exec(ctx, `DELETE FROM friendships WHERE status = 'accepted'
		AND LEAST(requester_id, addressee_id) = LEAST($1::uuid, $2::uuid)
		AND GREATEST(requester_id, addressee_id) = GREATEST($1::uuid, $2::uuid)`, a, b)
	return err
}

// sortFriends orders friends by name, then id, so the list is stable.
func sortFriends(fs []Friend) {
	sort.Slice(fs, func(i, j int) bool {
		if fs[i].DisplayName != fs[j].DisplayName {
			return fs[i].DisplayName < fs[j].DisplayName
		}
		return fs[i].ID.String() < fs[j].ID.String()
	})
}
