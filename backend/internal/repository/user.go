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

// UserRepository 封裝 users 表的資料庫存取操作。
type UserRepository struct {
	pool *pgxpool.Pool // PostgreSQL 連線池
}

// NewUserRepository 建立 UserRepository 實例。
func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

// Create 新增一筆使用者資料，回傳含有 DB 產生值 (id, avatar, created_at 等) 的完整 User。
func (repo *UserRepository) Create(ctx context.Context, user *model.User) (*model.User, error) {
	query := `
		INSERT INTO users (email, password_hash, display_name)
		VALUES ($1, $2, $3)
		RETURNING id, email, password_hash, display_name, avatar, role_id,
		          is_active, is_verified, created_at, updated_at
	`
	row := repo.pool.QueryRow(ctx, query, user.Email, user.PasswordHash, user.DisplayName)

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

// GetByEmail 以 Email 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *UserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
	return repo.getOneUser(ctx, "email", email)
}

// GetByID 以 UUID 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *UserRepository) GetByID(ctx context.Context, id string) (*model.User, error) {
	return repo.getOneUser(ctx, "id", id)
}

// DeleteByID 刪除指定 ID 的使用者。用於測試資料清理等場景。
func (repo *UserRepository) DeleteByID(ctx context.Context, id string) error {
	_, err := repo.pool.Exec(ctx, "DELETE FROM users WHERE id = $1", id)
	return err
}

// getOneUser 是內部共用方法，依指定欄位查詢單一使用者。
func (repo *UserRepository) getOneUser(ctx context.Context, column string, value string) (*model.User, error) {
	// 此處 column 為程式內部控制 ("id" 或 "email")，非外部輸入，可安全拼接
	query := `
		SELECT id, email, password_hash, display_name, avatar, role_id,
		       is_active, is_verified, created_at, updated_at
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
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &user, nil
}
