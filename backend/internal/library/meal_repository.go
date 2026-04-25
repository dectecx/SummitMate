package library

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

// MealLibraryRepository 定義餐食庫資料存取介面。
type MealLibraryRepository interface {
	Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error)
	GetByID(ctx context.Context, id string, userID string) (*MealLibraryItem, error)
	ListByUserID(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*MealLibraryItem, int, bool, error)
	Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error)
	Delete(ctx context.Context, id string, userID string) error
	ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error
}

type mealLibraryRepository struct {
	db database.DB
}

func NewMealLibraryRepository(db database.DB) MealLibraryRepository {
	return &mealLibraryRepository{db: db}
}

func (repo *mealLibraryRepository) Create(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	query := `
		INSERT INTO meal_library_items (user_id, name, weight, calories, notes, is_archived, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		item.UserID, item.Name, item.Weight, item.Calories, item.Notes, item.IsArchived, item.CreatedBy, item.UpdatedBy,
	)

	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("create meal library item: %w", err)
	}
	return it, nil
}

func (repo *mealLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*MealLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM meal_library_items
		WHERE id = $1 AND user_id = $2
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query, id, userID)
	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("get meal library item %s for user %s: %w", id, userID, err)
	}
	return it, nil
}

func (repo *mealLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*MealLibraryItem, int, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}

	whereClause := "WHERE user_id = $1 AND ($2 OR is_archived = false)"
	args := []any{userID, includeArchived}

	if search != "" {
		args = append(args, "%"+search+"%")
		whereClause += " AND name ILIKE $" + fmt.Sprint(len(args))
	}

	db := database.GetQuerier(ctx, repo.db)
	var total int
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM meal_library_items %s`, whereClause)
	if err := db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, false, fmt.Errorf("count meal library for user %s: %w", userID, err)
	}

	dataArgs := append(args, limit, (page-1)*limit)
	mainQuery := fmt.Sprintf(`
		SELECT id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM meal_library_items
		%s
		ORDER BY created_at DESC, id DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, len(args)+1, len(args)+2)

	rows, err := db.Query(ctx, mainQuery, dataArgs...)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query meal library for user %s: %w", userID, err)
	}
	defer rows.Close()

	var items []*MealLibraryItem
	for rows.Next() {
		item, err := repo.scanItem(rows)
		if err != nil {
			return nil, 0, false, fmt.Errorf("scan meal library row: %w", err)
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, false, fmt.Errorf("iterate meal library rows: %w", err)
	}

	return items, total, page*limit < total, nil
}

func (repo *mealLibraryRepository) Update(ctx context.Context, item *MealLibraryItem) (*MealLibraryItem, error) {
	query := `
		UPDATE meal_library_items
		SET name = $1, weight = $2, calories = $3, notes = $4, is_archived = $5, updated_at = NOW(), updated_by = $6
		WHERE id = $7 AND user_id = $8
		RETURNING id, user_id, name, weight, calories, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		item.Name, item.Weight, item.Calories, item.Notes, item.IsArchived, item.UpdatedBy, item.ID, item.UserID,
	)

	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("update meal library item %s for user %s: %w", item.ID, item.UserID, err)
	}
	return it, nil
}

func (repo *mealLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	query := `
		DELETE FROM meal_library_items
		WHERE id = $1 AND user_id = $2
	`
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, query, id, userID)
	if err != nil {
		return fmt.Errorf("delete meal library item %s for user %s: %w", id, userID, err)
	}
	return nil
}

func (repo *mealLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*MealLibraryItem) error {
	db := database.GetQuerier(ctx, repo.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, repo.db, func(txCtx context.Context) error {
			return repo.ReplaceAll(txCtx, userID, items)
		})
	}

	_, err := tx.Exec(ctx, "DELETE FROM meal_library_items WHERE user_id = $1", userID)
	if err != nil {
		return fmt.Errorf("replace all meal library (delete phase) for user %s: %w", userID, err)
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
			return fmt.Errorf("replace all meal library (insert phase) item %s for user %s: %w", item.ID, userID, err)
		}
	}

	return nil
}

func (repo *mealLibraryRepository) scanItem(row pgx.Row) (*MealLibraryItem, error) {
	var i MealLibraryItem
	err := row.Scan(
		&i.ID, &i.UserID, &i.Name, &i.Weight, &i.Calories,
		&i.Notes, &i.IsArchived,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, fmt.Errorf("scan meal library item: %w", err)
	}
	return &i, nil
}
