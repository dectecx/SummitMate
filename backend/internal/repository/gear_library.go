package repository

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

type GearLibraryRepository struct {
	pool *pgxpool.Pool
}

func NewGearLibraryRepository(pool *pgxpool.Pool) *GearLibraryRepository {
	return &GearLibraryRepository{pool: pool}
}

func (repo *GearLibraryRepository) Create(ctx context.Context, item *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	query := `
		INSERT INTO gear_library_items (user_id, name, weight, category, notes, is_archived, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.UserID, item.Name, item.Weight, item.Category, item.Notes, item.IsArchived, item.CreatedBy, item.UpdatedBy,
	)

	return repo.scanItem(row)
}

func (repo *GearLibraryRepository) GetByID(ctx context.Context, id string, userID string) (*model.GearLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM gear_library_items
		WHERE id = $1 AND user_id = $2
	`
	row := repo.pool.QueryRow(ctx, query, id, userID)
	return repo.scanItem(row)
}

func (repo *GearLibraryRepository) ListByUserID(ctx context.Context, userID string, includeArchived bool) ([]*model.GearLibraryItem, error) {
	query := `
		SELECT id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
		FROM gear_library_items
		WHERE user_id = $1 AND ($2 OR is_archived = false)
		ORDER BY created_at DESC
	`
	rows, err := repo.pool.Query(ctx, query, userID, includeArchived)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*model.GearLibraryItem
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

func (repo *GearLibraryRepository) Update(ctx context.Context, item *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	query := `
		UPDATE gear_library_items
		SET name = $1, weight = $2, category = $3, notes = $4, is_archived = $5, updated_at = NOW(), updated_by = $6
		WHERE id = $7 AND user_id = $8
		RETURNING id, user_id, name, weight, category, notes, is_archived, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.Name, item.Weight, item.Category, item.Notes, item.IsArchived, item.UpdatedBy, item.ID, item.UserID,
	)

	return repo.scanItem(row)
}

func (repo *GearLibraryRepository) Delete(ctx context.Context, id string, userID string) error {
	query := `
		DELETE FROM gear_library_items
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

func (repo *GearLibraryRepository) scanItem(row pgx.Row) (*model.GearLibraryItem, error) {
	var i model.GearLibraryItem
	err := row.Scan(
		&i.ID, &i.UserID, &i.Name, &i.Weight, &i.Category,
		&i.Notes, &i.IsArchived,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, err
	}
	return &i, nil
}
