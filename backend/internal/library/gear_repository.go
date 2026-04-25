package library

import (
	"context"

	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

// GearLibraryRepository 定義裝備庫資料存取介面。
type GearLibraryRepository interface {
	Create(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error)
	GetByID(ctx context.Context, id string, userID string) (*GearLibraryItem, error)
	ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*GearLibraryItem, error)
	Update(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error)
	Delete(ctx context.Context, id string, userID string) error
	ReplaceAll(ctx context.Context, userID string, items []*GearLibraryItem) error
}

type gearLibraryRepository struct {
	db database.DB
}

func NewGearLibraryRepository(db database.DB) GearLibraryRepository {
	return &gearLibraryRepository{db: db}
}

func (repo *gearLibraryRepository) Create(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error) {
	query := `
		INSERT INTO gear_library_items (user_id, name, weight, category, notes, is_archived, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		item.UserID, item.Name, item.Weight, item.Category, item.Notes, item.IsArchived, item.CreatedBy, item.UpdatedBy,
	)

	it, err := repo.scanItem(row)
 	if err != nil {
 		return nil, fmt.Errorf("create gear library item: %w", err)
 	}
 	return it, nil
}

func (repo *gearLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*GearLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM gear_library_items
		WHERE id = $1 AND user_id = $2
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query, id, userID)
	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("get gear library item %s for user %s: %w", id, userID, err)
	}
	return it, nil
}

func (repo *gearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*GearLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM gear_library_items
		WHERE user_id = $1 AND ($2 OR is_archived = false)
		ORDER BY created_at DESC
	`
	db := database.GetQuerier(ctx, repo.db)
	rows, err := db.Query(ctx, query, userID, includeArchived)
	if err != nil {
		return nil, fmt.Errorf("query gear library for user %s: %w", userID, err)
	}
	defer rows.Close()

	var items []*GearLibraryItem
	for rows.Next() {
		item, err := repo.scanItem(rows)
		if err != nil {
			return nil, fmt.Errorf("scan gear library row: %w", err)
		}
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate gear library rows: %w", err)
	}
	return items, nil
}

func (repo *gearLibraryRepository) Update(ctx context.Context, item *GearLibraryItem) (*GearLibraryItem, error) {
	query := `
		UPDATE gear_library_items
		SET name = $1, weight = $2, category = $3, notes = $4, is_archived = $5, updated_at = NOW(), updated_by = $6
		WHERE id = $7 AND user_id = $8
		RETURNING id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		item.Name, item.Weight, item.Category, item.Notes, item.IsArchived, item.UpdatedBy, item.ID, item.UserID,
	)

	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("update gear library item %s for user %s: %w", item.ID, item.UserID, err)
	}
	return it, nil
}

func (repo *gearLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	query := `
		DELETE FROM gear_library_items
		WHERE id = $1 AND user_id = $2
	`
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, query, id, userID)
	if err != nil {
		return fmt.Errorf("delete gear library item %s for user %s: %w", id, userID, err)
	}
	return nil
}

func (repo *gearLibraryRepository) ReplaceAll(ctx context.Context, userID string, items []*GearLibraryItem) error {
	db := database.GetQuerier(ctx, repo.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, repo.db, func(txCtx context.Context) error {
			return repo.ReplaceAll(txCtx, userID, items)
		})
	}

	_, err := tx.Exec(ctx, "DELETE FROM gear_library_items WHERE user_id = $1", userID)
	if err != nil {
		return fmt.Errorf("replace all gear library (delete phase) for user %s: %w", userID, err)
	}

	query := `
		INSERT INTO gear_library_items (id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8, NOW()), $9, COALESCE($10, NOW()), $11)
	`
	for _, item := range items {
		_, err := tx.Exec(ctx, query,
			item.ID, userID, item.Name, item.Weight, item.Category, item.Notes, item.IsArchived, item.CreatedAt, item.CreatedBy, item.UpdatedAt, item.UpdatedBy,
		)
		if err != nil {
			return fmt.Errorf("replace all gear library (insert phase) item %s for user %s: %w", item.ID, userID, err)
		}
	}

	return nil
}

func (repo *gearLibraryRepository) scanItem(row pgx.Row) (*GearLibraryItem, error) {
	var i GearLibraryItem
	err := row.Scan(
		&i.ID, &i.UserID, &i.Name, &i.Weight, &i.Category,
		&i.Notes, &i.IsArchived,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, fmt.Errorf("scan gear library item: %w", err)
	}
	return &i, nil
}
