package repository

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

type TripGearRepository struct {
	pool *pgxpool.Pool
}

func NewTripGearRepository(pool *pgxpool.Pool) *TripGearRepository {
	return &TripGearRepository{pool: pool}
}

func (repo *TripGearRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripGearItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
		FROM gear_items
		WHERE trip_id = $1
		ORDER BY order_index ASC NULLS LAST, created_at ASC
	`
	rows, err := repo.pool.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*model.TripGearItem
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

func (repo *TripGearRepository) Create(ctx context.Context, item *model.TripGearItem) (*model.TripGearItem, error) {
	query := `
		INSERT INTO gear_items (trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.TripID, item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.CreatedBy, item.UpdatedBy,
	)
	return repo.scanItem(row)
}

func (repo *TripGearRepository) GetByID(ctx context.Context, id string, tripID string) (*model.TripGearItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
		FROM gear_items
		WHERE id = $1 AND trip_id = $2
	`
	row := repo.pool.QueryRow(ctx, query, id, tripID)
	return repo.scanItem(row)
}

func (repo *TripGearRepository) Update(ctx context.Context, item *model.TripGearItem) (*model.TripGearItem, error) {
	query := `
		UPDATE gear_items
		SET library_item_id = $1, name = $2, weight = $3, category = $4, quantity = $5, is_checked = $6, order_index = $7, updated_at = NOW(), updated_by = $8
		WHERE id = $9 AND trip_id = $10
		RETURNING id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.UpdatedBy, item.ID, item.TripID,
	)
	return repo.scanItem(row)
}

func (repo *TripGearRepository) Delete(ctx context.Context, id string, tripID string) error {
	query := `
		DELETE FROM gear_items
		WHERE id = $1 AND trip_id = $2
	`
	commandTag, err := repo.pool.Exec(ctx, query, id, tripID)
	if err != nil {
		return err
	}
	if commandTag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (repo *TripGearRepository) ReplaceAll(ctx context.Context, tripID string, items []*model.TripGearItem) error {
	tx, err := repo.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, "DELETE FROM gear_items WHERE trip_id = $1", tripID)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO gear_items (id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, NOW()), $11, COALESCE($12, NOW()), $13)
	`
	for _, item := range items {
		// Ensure tripID is strictly applied from the route argument, ignoring what client sends
		_, err := tx.Exec(ctx, query,
			item.ID, tripID, item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.CreatedAt, item.CreatedBy, item.UpdatedAt, item.UpdatedBy,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (repo *TripGearRepository) scanItem(row pgx.Row) (*model.TripGearItem, error) {
	var i model.TripGearItem
	err := row.Scan(
		&i.ID, &i.TripID, &i.LibraryItemID, &i.Name, &i.Weight, &i.Category,
		&i.Quantity, &i.IsChecked, &i.OrderIndex,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, err
	}
	return &i, nil
}
