package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

var ErrNotFound = errors.New("resource not found")

type UserRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) *UserRepository {
	return &UserRepository{db: db}
}

// Create inserts a new user and returns the generated User struct.
func (r *UserRepository) Create(ctx context.Context, u *model.User) (*model.User, error) {
	query := `
		INSERT INTO users (email, password_hash, display_name)
		VALUES ($1, $2, $3)
		RETURNING id, email, password_hash, display_name, avatar, role_id, is_active, is_verified, created_at, updated_at
	`
	row := r.db.QueryRow(ctx, query, u.Email, u.PasswordHash, u.DisplayName)

	var created model.User
	err := row.Scan(
		&created.ID,
		&created.Email,
		&created.PasswordHash,
		&created.DisplayName,
		&created.Avatar,
		&created.RoleID,
		&created.IsActive,
		&created.IsVerified,
		&created.CreatedAt,
		&created.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &created, nil
}

// GetByEmail retrieves a user by their email.
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
	query := `
		SELECT id, email, password_hash, display_name, avatar, role_id, is_active, is_verified, created_at, updated_at
		FROM users
		WHERE email = $1
	`
	row := r.db.QueryRow(ctx, query, email)

	var u model.User
	err := row.Scan(
		&u.ID,
		&u.Email,
		&u.PasswordHash,
		&u.DisplayName,
		&u.Avatar,
		&u.RoleID,
		&u.IsActive,
		&u.IsVerified,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &u, nil
}

// GetByID retrieves a user by their ID.
func (r *UserRepository) GetByID(ctx context.Context, id string) (*model.User, error) {
	query := `
		SELECT id, email, password_hash, display_name, avatar, role_id, is_active, is_verified, created_at, updated_at
		FROM users
		WHERE id = $1
	`
	row := r.db.QueryRow(ctx, query, id)

	var u model.User
	err := row.Scan(
		&u.ID,
		&u.Email,
		&u.PasswordHash,
		&u.DisplayName,
		&u.Avatar,
		&u.RoleID,
		&u.IsActive,
		&u.IsVerified,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &u, nil
}
