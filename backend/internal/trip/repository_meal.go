package trip

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/database"
)

// TripMealRepository 定義行程餐食資料存取介面。
type TripMealRepository interface {
	ListByTripID(ctx context.Context, tripID string) ([]*TripMealItem, error)
	Create(ctx context.Context, item *TripMealItem) (*TripMealItem, error)
	GetByID(ctx context.Context, id string, tripID string) (*TripMealItem, error)
	Update(ctx context.Context, item *TripMealItem) (*TripMealItem, error)
	Delete(ctx context.Context, id string, tripID string) error
	ReplaceAll(ctx context.Context, tripID string, items []*TripMealItem) error
}

type tripMealRepository struct {
	pool *pgxpool.Pool
}

func NewTripMealRepository(pool *pgxpool.Pool) TripMealRepository {
	return &tripMealRepository{pool: pool}
}

func (repo *tripMealRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripMealItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
		FROM meal_items
		WHERE trip_id = $1
		ORDER BY day ASC, meal_type ASC, created_at ASC
	`
	db := database.GetQuerier(ctx, repo.pool)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*TripMealItem
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

func (repo *tripMealRepository) Create(ctx context.Context, item *TripMealItem) (*TripMealItem, error) {
	query := `
		INSERT INTO meal_items (trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.TripID, item.LibraryItemID, item.Day, item.MealType, item.Name, item.Weight, item.Calories, item.Quantity, item.Note, item.CreatedBy, item.UpdatedBy,
	)
	return repo.scanItem(row)
}

func (repo *tripMealRepository) GetByID(ctx context.Context, id string, tripID string) (*TripMealItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
		FROM meal_items
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, id, tripID)
	return repo.scanItem(row)
}

func (repo *tripMealRepository) Update(ctx context.Context, item *TripMealItem) (*TripMealItem, error) {
	query := `
		UPDATE meal_items
		SET library_item_id = $1, day = $2, meal_type = $3, name = $4, weight = $5, calories = $6, quantity = $7, note = $8, updated_at = NOW(), updated_by = $9
		WHERE id = $10 AND trip_id = $11
		RETURNING id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.LibraryItemID, item.Day, item.MealType, item.Name, item.Weight, item.Calories, item.Quantity, item.Note, item.UpdatedBy, item.ID, item.TripID,
	)
	return repo.scanItem(row)
}

func (repo *tripMealRepository) Delete(ctx context.Context, id string, tripID string) error {
	query := `
		DELETE FROM meal_items
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	commandTag, err := db.Exec(ctx, query, id, tripID)
	if err != nil {
		return err
	}
	if commandTag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (repo *tripMealRepository) ReplaceAll(ctx context.Context, tripID string, items []*TripMealItem) error {
	db := database.GetQuerier(ctx, repo.pool)

	// If an outer transaction was injected via context (e.g., from a service-level
	// WithTransaction call), use it directly so ReplaceAll participates in that transaction.
	// Otherwise, start a local transaction to guarantee atomicity for the delete + insert pair.
	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, repo.pool, func(txCtx context.Context) error {
			return repo.ReplaceAll(txCtx, tripID, items)
		})
	}

	_, err := tx.Exec(ctx, "DELETE FROM meal_items WHERE trip_id = $1", tripID)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO meal_items (id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, COALESCE($11, NOW()), $12, COALESCE($13, NOW()), $14)
	`
	for _, item := range items {
		_, err := tx.Exec(ctx, query,
			item.ID, tripID, item.LibraryItemID, item.Day, item.MealType, item.Name, item.Weight, item.Calories, item.Quantity, item.Note, item.CreatedAt, item.CreatedBy, item.UpdatedAt, item.UpdatedBy,
		)
		if err != nil {
			return err
		}
	}

	return nil
}

func (repo *tripMealRepository) scanItem(row pgx.Row) (*TripMealItem, error) {
	var i TripMealItem
	err := row.Scan(
		&i.ID, &i.TripID, &i.LibraryItemID, &i.Day, &i.MealType, &i.Name,
		&i.Weight, &i.Calories, &i.Quantity, &i.Note,
		&i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		return nil, err
	}
	return &i, nil
}
