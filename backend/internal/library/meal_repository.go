package library

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// MealLibraryRepository 定義餐食庫資料存取介面。
type MealLibraryRepository interface {
	Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error)
	GetByID(ctx context.Context, id string, userID string) (*MealLibraryItem, error)
	ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*MealLibraryItem, error)
	Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error)
	Delete(ctx context.Context, id string, userID string) error
	ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error
}

type mealLibraryRepository struct {
	pool *pgxpool.Pool
}

func NewMealLibraryRepository(pool *pgxpool.Pool) MealLibraryRepository {
	return &mealLibraryRepository{pool: pool}
}

func (repo *mealLibraryRepository) Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	query := `
		INSERT INTO meal_library_items (user_id, name, weight, calories, notes, is_archived, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.UserID, item.Name, item.Weight, item.Calories, item.Notes, item.IsArchived, item.CreatedBy, item.UpdatedBy,
	)

	return repo.scanItem(row)
}

func (repo *mealLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*MealLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM meal_library_items
		WHERE id = $1 AND user_id = $2
	`
	row := repo.pool.QueryRow(ctx, query, id, userID)
	return repo.scanItem(row)
}

func (repo *mealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*MealLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM meal_library_items
		WHERE user_id = $1 AND ($2 OR is_archived = false)
		ORDER BY created_at DESC
	`
	rows, err := repo.pool.Query(ctx, query, userID, includeArchived)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*MealLibraryItem
	for rows.Next() {
		item, err := repo.scanItem(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (repo *mealLibraryRepository) Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	query := `
		UPDATE meal_library_items
		SET name = $1, weight = $2, calories = $3, notes = $4, is_archived = $5, updated_at = NOW(), updated_by = $6
		WHERE id = $7 AND user_id = $8
		RETURNING id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.Name, item.Weight, item.Calories, item.Notes, item.IsArchived, item.UpdatedBy, item.ID, item.UserID,
	)

	return repo.scanItem(row)
}

func (repo *mealLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	query := `
		DELETE FROM meal_library_items
		WHERE id = $1 AND user_id = $2
	`
	commandTag, err := repo.pool.Exec(ctx, query, id, userID)
	if err != nil {
		return err
	}
	if commandTag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (repo *mealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error {
	tx, err := repo.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, "DELETE FROM meal_library_items WHERE user_id = $1", userID)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO meal_library_items (id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8, NOW()), $9, COALESCE($10, NOW()), $11)
	`
	for _, item := range items {
		_, err := tx.Exec(ctx, query,
			item.ID, userID, item.Name, item.Weight, item.Calories, item.Notes, item.IsArchived, item.CreatedAt, item.CreatedBy, item.UpdatedAt, item.UpdatedBy,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (repo *mealLibraryRepository) scanItem(row pgx.Row) (*MealLibraryItem, error) {
	var i MealLibraryItem
	err := row.Scan(
		&i.ID, &i.UserID, &i.Name, &i.Weight, &i.Calories,
		&i.Notes, &i.IsArchived,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, err
	}
	return &i, nil
}
