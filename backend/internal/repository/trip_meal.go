package repository

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

type TripMealRepository struct {
	pool *pgxpool.Pool
}

func NewTripMealRepository(pool *pgxpool.Pool) *TripMealRepository {
	return &TripMealRepository{pool: pool}
}

func (repo *TripMealRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripMealItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
		FROM meal_items
		WHERE trip_id = $1
		ORDER BY day ASC, meal_type ASC, created_at ASC
	`
	rows, err := repo.pool.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*model.TripMealItem
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

func (repo *TripMealRepository) Create(ctx context.Context, item *model.TripMealItem) (*model.TripMealItem, error) {
	query := `
		INSERT INTO meal_items (trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.TripID, item.LibraryItemID, item.Day, item.MealType, item.Name, item.Weight, item.Calories, item.Quantity, item.Note, item.CreatedBy, item.UpdatedBy,
	)
	return repo.scanItem(row)
}

func (repo *TripMealRepository) GetByID(ctx context.Context, id string, tripID string) (*model.TripMealItem, error) {
	query := `
		SELECT id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
		FROM meal_items
		WHERE id = $1 AND trip_id = $2
	`
	row := repo.pool.QueryRow(ctx, query, id, tripID)
	return repo.scanItem(row)
}

func (repo *TripMealRepository) Update(ctx context.Context, item *model.TripMealItem) (*model.TripMealItem, error) {
	query := `
		UPDATE meal_items
		SET library_item_id = $1, day = $2, meal_type = $3, name = $4, weight = $5, calories = $6, quantity = $7, note = $8, updated_at = NOW(), updated_by = $9
		WHERE id = $10 AND trip_id = $11
		RETURNING id, trip_id, library_item_id, day, meal_type, name, weight, calories, quantity, note, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		item.LibraryItemID, item.Day, item.MealType, item.Name, item.Weight, item.Calories, item.Quantity, item.Note, item.UpdatedBy, item.ID, item.TripID,
	)
	return repo.scanItem(row)
}

func (repo *TripMealRepository) Delete(ctx context.Context, id string, tripID string) error {
	query := `
		DELETE FROM meal_items
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

func (repo *TripMealRepository) scanItem(row pgx.Row) (*model.TripMealItem, error) {
	var i model.TripMealItem
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
