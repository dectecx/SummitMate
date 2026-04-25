package auth

import (
	"context"
	"errors"

	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

// ErrNotFound 代表查詢結果為空 (無符合條件的資料列)。
var ErrNotFound = errors.New("resource not found")

// UserRepository 定義使用者資料存取介面。
type UserRepository interface {
	Create(ctx context.Context, user *User) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	GetByID(ctx context.Context, id string) (*User, error)
	DeleteByID(ctx context.Context, id string) error
	Update(ctx context.Context, id string, displayName, avatar *string) (*User, error)
	SoftDelete(ctx context.Context, id string) error
	SetVerified(ctx context.Context, id string) error
}

type userRepository struct {
	db database.Querier
}

func NewUserRepository(db database.Querier) UserRepository {
	return &userRepository{db: db}
}

// Create 新增一筆使用者資料，回傳含有 DB 產生值 (id, avatar, created_at 等) 的完整 User。
func (repo *userRepository) Create(ctx context.Context, user *User) (*User, error) {
	query := `
		INSERT INTO users (email, password_hash, display_name, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, email, password_hash, display_name, avatar, role_id,
		          (SELECT code FROM roles WHERE id = users.role_id) as role_code,
		          is_active, is_verified,
		          created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		user.Email,
		user.PasswordHash,
		user.DisplayName,
		user.CreatedBy,
		user.UpdatedBy,
	)

	var created User
	err := row.Scan(
		&created.ID,
		&created.Email,
		&created.PasswordHash,
		&created.DisplayName,
		&created.Avatar,
		&created.RoleID,
		&created.RoleCode,
		&created.IsActive,
		&created.IsVerified,
		&created.CreatedAt,
		&created.CreatedBy,
		&created.UpdatedAt,
		&created.UpdatedBy,
	)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	return &created, nil
}

// GetByEmail 以 Email 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *userRepository) GetByEmail(ctx context.Context, email string) (*User, error) {
	user, err := repo.getOneUser(ctx, "email", email)
	if err != nil {
		return nil, fmt.Errorf("get user by email %s: %w", email, err)
	}
	return user, nil
}

// GetByID 以 UUID 查詢使用者。若不存在回傳 ErrNotFound。
func (repo *userRepository) GetByID(ctx context.Context, id string) (*User, error) {
	user, err := repo.getOneUser(ctx, "id", id)
	if err != nil {
		return nil, fmt.Errorf("get user by id %s: %w", id, err)
	}
	return user, nil
}

// DeleteByID 刪除指定 ID 的使用者。用於測試資料清理等場景。
func (repo *userRepository) DeleteByID(ctx context.Context, id string) error {
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, "DELETE FROM users WHERE id = $1", id)
	if err != nil {
		return fmt.Errorf("delete user %s: %w", id, err)
	}
	return nil
}

// Update 更新使用者的 display_name 與 avatar。
func (repo *userRepository) Update(ctx context.Context, id string, displayName, avatar *string) (*User, error) {
	query := `
		UPDATE users
		SET display_name = COALESCE($1, display_name),
			avatar = COALESCE($2, avatar),
			updated_at = NOW(),
			updated_by = $3
		WHERE id = $3
		RETURNING id, email, password_hash, display_name, avatar, role_id,
		          (SELECT code FROM roles WHERE id = users.role_id) as role_code,
		          is_active, is_verified,
		          created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
 	row := db.QueryRow(ctx, query, displayName, avatar, id)

	var user User
	err := row.Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.Avatar,
		&user.RoleID,
		&user.RoleCode,
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
		return nil, fmt.Errorf("update user %s: %w", id, err)
	}
	return &user, nil
}

// SoftDelete 將使用者設為停用 (is_active = false)。
func (repo *userRepository) SoftDelete(ctx context.Context, id string) error {
	db := database.GetQuerier(ctx, repo.db)
	result, err := db.Exec(ctx, "UPDATE users SET is_active = false, updated_at = NOW(), updated_by = $1 WHERE id = $1", id)
	if err != nil {
		return fmt.Errorf("soft delete user %s: %w", id, err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// SetVerified 將使用者設為已驗證。
func (repo *userRepository) SetVerified(ctx context.Context, id string) error {
	query := "UPDATE users SET is_verified = true, updated_at = NOW() WHERE id = $1"
	db := database.GetQuerier(ctx, repo.db)
	result, err := db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("set verified for user %s: %w", id, err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// getOneUser 是內部共用方法，依指定欄位查詢單一使用者。
func (repo *userRepository) getOneUser(ctx context.Context, column string, value string) (*User, error) {
	// 此處 column 為程式內部控制 ("id" 或 "email")，非外部輸入，可安全拼接
	query := `
		SELECT u.id, u.email, u.password_hash, u.display_name, u.avatar, u.role_id,
		       r.code as role_code,
		       u.is_active, u.is_verified,
		       u.created_at, u.created_by, u.updated_at, u.updated_by
		FROM users u
		LEFT JOIN roles r ON u.role_id = r.id
		WHERE u.` + column + ` = $1
	`
	db := database.GetQuerier(ctx, repo.db)
 	row := db.QueryRow(ctx, query, value)

	var user User
	err := row.Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.Avatar,
		&user.RoleID,
		&user.RoleCode,
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
		return nil, fmt.Errorf("scan user: %w", err)
	}

	return &user, nil
}
