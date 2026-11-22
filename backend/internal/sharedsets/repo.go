package sharedsets

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/gearset"
)

// ErrNotFound is returned when a set does not exist or was deleted.
var ErrNotFound = errors.New("shared set not found")

// Set is a stored shared set. Items are only loaded by Get.
type Set struct {
	ID          uuid.UUID
	OwnerID     uuid.UUID
	Title       string
	AuthorName  string
	Visibility  string
	KeyHash     string // protected sets only
	Items       []gearset.Item
	TotalWeight float64
	GearCount   int
	MealCount   int
	CreatedAt   time.Time
}

// Cursor is the keyset position of the last row of a page.
type Cursor struct {
	CreatedAt time.Time
	ID        uuid.UUID
}

// ListQuery selects one page of summaries.
type ListQuery struct {
	Mine  bool      // true: Owner's sets of every visibility; false: public and protected sets
	Owner uuid.UUID // used when Mine
	Q     string    // title substring, unescaped
	Limit int
	After *Cursor
}

// Repository is the storage port.
type Repository interface {
	Create(ctx context.Context, s Set) error
	Get(ctx context.Context, id uuid.UUID) (Set, error)
	List(ctx context.Context, q ListQuery) ([]Set, error)
	// Delete soft-deletes a live set owned by owner; false when there is no such set.
	Delete(ctx context.Context, id, owner uuid.UUID) (bool, error)
	DisplayName(ctx context.Context, userID uuid.UUID) (string, error)
}

// PgRepository is the PostgreSQL implementation.
type PgRepository struct{ pool *pgxpool.Pool }

func NewPgRepository(pool *pgxpool.Pool) *PgRepository { return &PgRepository{pool: pool} }

func (r *PgRepository) Create(ctx context.Context, s Set) error {
	items, err := json.Marshal(s.Items)
	if err != nil {
		return err
	}
	var key *string
	if s.KeyHash != "" {
		key = &s.KeyHash
	}
	return r.pool.QueryRow(ctx, `INSERT INTO shared_sets
		(id, owner_id, title, author_name, visibility, access_key_hash, items, total_weight, gear_count, meal_count)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING created_at`,
		s.ID, s.OwnerID, s.Title, s.AuthorName, s.Visibility, key, items, s.TotalWeight, s.GearCount, s.MealCount).
		Scan(&s.CreatedAt)
}

func (r *PgRepository) Get(ctx context.Context, id uuid.UUID) (Set, error) {
	var s Set
	var key *string
	var items []byte
	err := r.pool.QueryRow(ctx, `SELECT id, owner_id, title, author_name, visibility, access_key_hash, items,
		total_weight, gear_count, meal_count, created_at FROM shared_sets WHERE id = $1 AND deleted_at IS NULL`, id).
		Scan(&s.ID, &s.OwnerID, &s.Title, &s.AuthorName, &s.Visibility, &key, &items,
			&s.TotalWeight, &s.GearCount, &s.MealCount, &s.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Set{}, ErrNotFound
	}
	if err != nil {
		return Set{}, err
	}
	if key != nil {
		s.KeyHash = *key
	}
	if err := json.Unmarshal(items, &s.Items); err != nil {
		return Set{}, err
	}
	return s, nil
}

// likeEscaper escapes LIKE wildcards for use with ESCAPE '\'.
var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

func (r *PgRepository) List(ctx context.Context, q ListQuery) ([]Set, error) {
	where := []string{"deleted_at IS NULL"}
	args := []any{}
	arg := func(v any) string {
		args = append(args, v)
		return "$" + strconv.Itoa(len(args))
	}
	if q.Mine {
		where = append(where, "owner_id = "+arg(q.Owner))
	} else {
		where = append(where, "visibility <> 'private'")
	}
	if q.Q != "" {
		where = append(where, `title ILIKE `+arg("%"+likeEscaper.Replace(q.Q)+"%")+` ESCAPE '\'`)
	}
	if q.After != nil {
		where = append(where, "(created_at, id) < ("+arg(q.After.CreatedAt)+", "+arg(q.After.ID)+")")
	}
	sql := `SELECT id, owner_id, title, author_name, visibility, total_weight, gear_count, meal_count, created_at
		FROM shared_sets WHERE ` + strings.Join(where, " AND ") +
		` ORDER BY created_at DESC, id DESC LIMIT ` + arg(q.Limit)
	rows, err := r.pool.Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Set
	for rows.Next() {
		var s Set
		if err := rows.Scan(&s.ID, &s.OwnerID, &s.Title, &s.AuthorName, &s.Visibility,
			&s.TotalWeight, &s.GearCount, &s.MealCount, &s.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, rows.Err()
}

func (r *PgRepository) Delete(ctx context.Context, id, owner uuid.UUID) (bool, error) {
	tag, err := r.pool.Exec(ctx, `UPDATE shared_sets SET deleted_at = clock_timestamp()
		WHERE id = $1 AND owner_id = $2 AND deleted_at IS NULL`, id, owner)
	return tag.RowsAffected() > 0, err
}

func (r *PgRepository) DisplayName(ctx context.Context, userID uuid.UUID) (string, error) {
	var name string
	err := r.pool.QueryRow(ctx, `SELECT display_name FROM users WHERE id = $1`, userID).Scan(&name)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	return name, err
}
