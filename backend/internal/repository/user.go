package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

// ErrNotFound 代表查詢結果為空 (無符合條件的資料列)。
var ErrNotFound = errors.New("resource not found")

// UserRepository 定義使用者資料存取介面。
type UserRepository interface {
	Create(ctx context.Context, user *model.User) (*model.User, error)
	GetByEmail(ctx context.Context, email string) (*model.User, error)
	GetByID(ctx context.Context, id string) (*model.User, error)
	DeleteByID(ctx context.Context, id string) error
	Update(ctx context.Context, id string, displayName, avatar *string) (*model.User, error)
	SoftDelete(ctx context.Context, id string) error
}

type userRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) UserRepository {
	return &userRepository{pool: pool}
}

// Create 新增一筆使用者資料，回傳含有 DB 產生值 (id, avatar, created_at 等) 的完整 User。
func (repo *userRepository) Create(ctx context.Context, user *model.User) (*model.User, error) {
	query := `
		INSERT INTO users (email, password_hash, display_name, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, email, password_hash, display_name, avatar, role_id,
		          is_active, is_verified, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query, user.Email, user.PasswordHash, user.DisplayName, user.CreatedBy, user.UpdatedBy)

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
		&created.CreatedBy,
		&created.UpdatedAt,
		&created.UpdatedBy,
	)
	if err != nil {
		return nil, err
	}

	return &created, nil
}

// GetByEmail 以 Email 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *userRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
	return repo.getOneUser(ctx, "email", email)
}

// GetByID 以 UUID 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *userRepository) GetByID(ctx context.Context, id string) (*model.User, error) {
	return repo.getOneUser(ctx, "id", id)
}

// DeleteByID 刪除指定 ID 的使用者。用於測試資料清理等場景。
func (repo *userRepository) DeleteByID(ctx context.Context, id string) error {
	_, err := repo.pool.Exec(ctx, "DELETE FROM users WHERE id = $1", id)
	return err
}

// Update 更新使用者的 display_name 與 avatar。
func (repo *userRepository) Update(ctx context.Context, id string, displayName, avatar *string) (*model.User, error) {
	query := `
		UPDATE users
		SET display_name = COALESCE($1, display_name),
		    avatar = COALESCE($2, avatar),
		    updated_at = NOW(),
		    updated_by = $3
		WHERE id = $3
		RETURNING id, email, password_hash, display_name, avatar, role_id,
		          is_active, is_verified, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query, displayName, avatar, id)

	var user model.User
	err := row.Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.Avatar,
		&user.RoleID,
		&user.IsActive,
		&user.IsVerified,
		&user.CreatedAt,
		&user.CreatedBy,
		&user.UpdatedAt,
		&user.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &user, nil
}

// SoftDelete 將使用者設為停用 (is_active = false)。
func (repo *userRepository) SoftDelete(ctx context.Context, id string) error {
	result, err := repo.pool.Exec(ctx, "UPDATE users SET is_active = false, updated_at = NOW(), updated_by = $1 WHERE id = $1", id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// getOneUser 是內部共用方法，依指定欄位查詢單一使用者。
func (repo *userRepository) getOneUser(ctx context.Context, column string, value string) (*model.User, error) {
	// 此處 column 為程式內部控制 ("id" 或 "email")，非外部輸入，可安全拼接
	query := `
		SELECT id, email, password_hash, display_name, avatar, role_id,
		       is_active, is_verified, created_at, created_by, updated_at, updated_by
		FROM users
		WHERE ` + column + ` = $1
	`
	row := repo.pool.QueryRow(ctx, query, value)

	var user model.User
	err := row.Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.Avatar,
		&user.RoleID,
		&user.IsActive,
		&user.IsVerified,
		&user.CreatedAt,
		&user.CreatedBy,
		&user.UpdatedAt,
		&user.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &user, nil
}
