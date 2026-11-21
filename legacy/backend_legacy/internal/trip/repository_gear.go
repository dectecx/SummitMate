package trip

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/database"
)

// TripGearRepository 定義行程裝備資料存取介面。
type TripGearRepository interface {
	ListByTripID(ctx context.Context, tripID string) ([]*TripGearItem, error)
	Create(ctx context.Context, item *TripGearItem) (*TripGearItem, error)
	GetByID(ctx context.Context, id string, tripID string) (*TripGearItem, error)
	Update(ctx context.Context, item *TripGearItem) (*TripGearItem, error)
	Delete(ctx context.Context, id string, tripID string) error
	ReplaceAll(ctx context.Context, tripID string, items []*TripGearItem) error
}

type tripGearRepository struct {
	pool *pgxpool.Pool
}

func NewTripGearRepository(pool *pgxpool.Pool) TripGearRepository {
	return &tripGearRepository{pool: pool}
}

func (repo *tripGearRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripGearItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
		FROM gear_items
		WHERE trip_id = $1
		ORDER BY order_index ASC NULLS LAST, created_at ASC
	`
	db := database.GetQuerier(ctx, repo.pool)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, fmt.Errorf("query gear for trip %s: %w", tripID, err)
	}
	defer rows.Close()

	var items []*TripGearItem
	for rows.Next() {
		item, err := repo.scanItem(rows)
		if err != nil {
			return nil, fmt.Errorf("scan gear item row: %w", err)
		}
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate gear item rows: %w", err)
	}
	return items, nil
}

func (repo *tripGearRepository) Create(ctx context.Context, item *TripGearItem) (*TripGearItem, error) {
	query := `
		INSERT INTO gear_items (trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.TripID, item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.CreatedBy, item.UpdatedBy,
	)
	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("create gear item: %w", err)
	}
	return it, nil
}

func (repo *tripGearRepository) GetByID(ctx context.Context, id string, tripID string) (*TripGearItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
		FROM gear_items
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, id, tripID)
	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("get gear item %s in trip %s: %w", id, tripID, err)
	}
	return it, nil
}

func (repo *tripGearRepository) Update(ctx context.Context, item *TripGearItem) (*TripGearItem, error) {
	query := `
		UPDATE gear_items
		SET library_item_id = $1, name = $2, weight = $3, category = $4, quantity = $5, is_checked = $6, order_index = $7, updated_at = NOW(), updated_by = $8
		WHERE id = $9 AND trip_id = $10
		RETURNING id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.UpdatedBy, item.ID, item.TripID,
	)
	it, err := repo.scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("update gear item %s in trip %s: %w", item.ID, item.TripID, err)
	}
	return it, nil
}

func (repo *tripGearRepository) Delete(ctx context.Context, id string, tripID string) error {
	query := `
		DELETE FROM gear_items
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	_, err := db.Exec(ctx, query, id, tripID)
	if err != nil {
		return fmt.Errorf("delete gear item %s in trip %s: %w", id, tripID, err)
	}
	return nil
}

func (repo *tripGearRepository) ReplaceAll(ctx context.Context, tripID string, items []*TripGearItem) error {
	db := database.GetQuerier(ctx, repo.pool)

	// If an outer transaction was injected via context (e.g., from a service-level
	// WithTransaction call), use it directly so ReplaceAll participates in that transaction.
	// Otherwise, start a local transaction to guarantee atomicity for the delete + insert pair.
	tx, ok := db.(pgx.Tx)
	if !ok {
		// Start a local transaction if not provided
		return database.WithTransaction(ctx, repo.pool, func(txCtx context.Context) error {
			return repo.ReplaceAll(txCtx, tripID, items)
		})
	}

	_, err := tx.Exec(ctx, "DELETE FROM gear_items WHERE trip_id = $1", tripID)
	if err != nil {
		return fmt.Errorf("replace all gear (delete phase) for trip %s: %w", tripID, err)
	}

	query := `
		INSERT INTO gear_items (id, trip_id, library_item_id, name, weight, category, quantity, is_checked, order_index, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, NOW()), $11, COALESCE($12, NOW()), $13)
	`
	for _, item := range items {
		_, err := tx.Exec(ctx, query,
			item.ID, tripID, item.LibraryItemID, item.Name, item.Weight, item.Category, item.Quantity, item.IsChecked, item.OrderIndex, item.CreatedAt, item.CreatedBy, item.UpdatedAt, item.UpdatedBy,
		)
		if err != nil {
			return fmt.Errorf("replace all gear (insert phase) item %s for trip %s: %w", item.ID, tripID, err)
		}
	}

	return nil
}

func (repo *tripGearRepository) scanItem(row pgx.Row) (*TripGearItem, error) {
	var i TripGearItem
	err := row.Scan(
		&i.ID, &i.TripID, &i.LibraryItemID, &i.Name, &i.Weight, &i.Category,
		&i.Quantity, &i.IsChecked, &i.OrderIndex,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, fmt.Errorf("scan gear item: %w", err)
	}
	return &i, nil
}
