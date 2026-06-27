package database

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Querier defines the common interface for database operations,
// satisfied by both *pgxpool.Pool and pgx.Tx.
type Querier interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error)
	SendBatch(ctx context.Context, b *pgx.Batch) pgx.BatchResults
}

// Beginner defines the interface for starting a transaction.
type Beginner interface {
	Begin(ctx context.Context) (pgx.Tx, error)
}

// DB combines Querier and Beginner interfaces.
type DB interface {
	Querier
	Beginner
}

type txKey struct{}

// WithTransaction runs a function within a database transaction.
// It injects the transaction into the context so repositories can retrieve it.
func WithTransaction(ctx context.Context, db Beginner, fn func(context.Context) error) error {
	tx, err := db.Begin(ctx)
	if err != nil {
		return err
	}

	defer func() {
		if p := recover(); p != nil {
			tx.Rollback(ctx)
			panic(p) // re-throw panic after rollback
		}
	}()

	// Inject tx into context
	txCtx := context.WithValue(ctx, txKey{}, tx)

	if err := fn(txCtx); err != nil {
		tx.Rollback(ctx)
		return err
	}

	return tx.Commit(ctx)
}

// GetQuerier returns the transaction from context if it exists,
// otherwise it returns the provided fallback querier.
func GetQuerier(ctx context.Context, fallback Querier) Querier {
	if tx, ok := ctx.Value(txKey{}).(pgx.Tx); ok {
		return tx
	}
	return fallback
}

// PoolConfig holds the tunable parameters for the pgx connection pool.
type PoolConfig struct {
	MaxConns          int
	MinConns          int
	MaxConnLifetime   time.Duration
	MaxConnIdleTime   time.Duration
	HealthCheckPeriod time.Duration
	ConnectTimeout    time.Duration
}

// DefaultPoolConfig returns the built-in pool defaults. It is used by callers
// (such as tests and the weather job) that do not load the full app config.
func DefaultPoolConfig() PoolConfig {
	return PoolConfig{
		MaxConns:          10,
		MinConns:          2,
		MaxConnLifetime:   30 * time.Minute,
		MaxConnIdleTime:   5 * time.Minute,
		HealthCheckPeriod: 1 * time.Minute,
		ConnectTimeout:    10 * time.Second,
	}
}

// Connect creates a pgx connection pool using the supplied pool configuration.
//
// Acquire timeout note: pgx v5's pgxpool has no pool-level acquire timeout
// (the v4 AcquireTimeout option was removed). The time spent waiting for a free
// connection when the pool is exhausted is bounded by the context passed to the
// query/acquire call. For HTTP traffic this is the request-scoped context set by
// the chi Timeout middleware (HTTP_REQUEST_TIMEOUT). ConnectTimeout below only
// bounds establishing a brand-new TCP/TLS connection, not waiting on the pool.
func Connect(ctx context.Context, databaseURL string, poolCfg PoolConfig) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse database URL: %w", err)
	}

	config.MaxConns = int32(poolCfg.MaxConns)
	config.MinConns = int32(poolCfg.MinConns)
	config.MaxConnLifetime = poolCfg.MaxConnLifetime
	config.MaxConnIdleTime = poolCfg.MaxConnIdleTime
	if poolCfg.HealthCheckPeriod > 0 {
		config.HealthCheckPeriod = poolCfg.HealthCheckPeriod
	}
	if poolCfg.ConnectTimeout > 0 {
		config.ConnConfig.ConnectTimeout = poolCfg.ConnectTimeout
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}

	slog.Info("Database connected")
	return pool, nil
}

// SetSessionUser sets the custom app.current_user_id variable in the database session.
// This is used by audit triggers to trace the user making the change.
func SetSessionUser(ctx context.Context, q Querier, userID string) error {
	if userID == "" {
		return nil
	}
	_, err := q.Exec(ctx, "SELECT set_config('app.current_user_id', $1, true)", userID)
	return err
}
