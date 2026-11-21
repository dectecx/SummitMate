package auth

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/store"
)

// ErrNotFound is returned by a Repository when a row does not exist.
var ErrNotFound = errors.New("not found")

// Repository is the persistence the auth Service needs. It is satisfied by
// store.Queries (via PgRepository); tests use an in-memory fake.
type Repository interface {
	CreateUser(ctx context.Context, arg store.CreateUserParams) (store.User, error)
	GetUserByEmail(ctx context.Context, email string) (store.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (store.User, error)
	MarkUserVerified(ctx context.Context, id uuid.UUID) error
	TouchUserLogin(ctx context.Context, id uuid.UUID) error
	UpdateUserProfile(ctx context.Context, arg store.UpdateUserProfileParams) (store.User, error)
	UpdateUserPassword(ctx context.Context, arg store.UpdateUserPasswordParams) error
	DeactivateUser(ctx context.Context, id uuid.UUID) error

	UpsertVerification(ctx context.Context, arg store.UpsertVerificationParams) error
	GetVerification(ctx context.Context, userID uuid.UUID) (store.EmailVerification, error)
	IncrementVerificationAttempts(ctx context.Context, userID uuid.UUID) (int32, error)
	DeleteVerification(ctx context.Context, userID uuid.UUID) error

	CreateRefreshToken(ctx context.Context, arg store.CreateRefreshTokenParams) (store.RefreshToken, error)
	GetRefreshTokenByHash(ctx context.Context, tokenHash string) (store.RefreshToken, error)
	RevokeRefreshToken(ctx context.Context, arg store.RevokeRefreshTokenParams) error
	RevokeAllRefreshTokens(ctx context.Context, userID uuid.UUID) error

	// InTx runs fn atomically; fn receives a Repository bound to the transaction.
	InTx(ctx context.Context, fn func(Repository) error) error
}

// PgRepository implements Repository on PostgreSQL.
type PgRepository struct {
	*store.Queries
	pool *pgxpool.Pool
}

func NewPgRepository(pool *pgxpool.Pool) *PgRepository {
	return &PgRepository{Queries: store.New(pool), pool: pool}
}

func (r *PgRepository) InTx(ctx context.Context, fn func(Repository) error) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // no-op after commit
	if err := fn(&PgRepository{Queries: r.Queries.WithTx(tx), pool: r.pool}); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// isNotFound reports whether err means "no such row" for either backend.
func isNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows) || errors.Is(err, ErrNotFound)
}
