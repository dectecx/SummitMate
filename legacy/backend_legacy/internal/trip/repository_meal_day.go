package trip

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/database"
)

type TripMealPlanDayRepository interface {
	ListByTripID(ctx context.Context, tripID string) ([]*MealPlanDay, error)
	Create(ctx context.Context, item *MealPlanDay) (*MealPlanDay, error)
	Update(ctx context.Context, item *MealPlanDay) (*MealPlanDay, error)
	Delete(ctx context.Context, id string, tripID string) error
	GetByID(ctx context.Context, id string, tripID string) (*MealPlanDay, error)
	ReplaceAll(ctx context.Context, tripID string, days []*MealPlanDay) error
}

type tripMealPlanDayRepository struct {
	pool *pgxpool.Pool
}

func NewTripMealPlanDayRepository(pool *pgxpool.Pool) TripMealPlanDayRepository {
	return &tripMealPlanDayRepository{pool: pool}
}

func (repo *tripMealPlanDayRepository) ListByTripID(ctx context.Context, tripID string) ([]*MealPlanDay, error) {
	query := `
		SELECT id, trip_id, name, linked_itinerary_day, created_at, updated_at
		FROM trip_meal_plan_days
		WHERE trip_id = $1
		ORDER BY created_at ASC
	`
	db := database.GetQuerier(ctx, repo.pool)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, fmt.Errorf("query meal plan days for trip %s: %w", tripID, err)
	}
	defer rows.Close()

	var days []*MealPlanDay
	for rows.Next() {
		d, err := repo.scanDay(rows)
		if err != nil {
			return nil, fmt.Errorf("scan meal plan day row: %w", err)
		}
		days = append(days, d)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate meal plan day rows: %w", err)
	}
	return days, nil
}

func (repo *tripMealPlanDayRepository) Create(ctx context.Context, d *MealPlanDay) (*MealPlanDay, error) {
	query := `
		INSERT INTO trip_meal_plan_days (trip_id, name, linked_itinerary_day)
		VALUES ($1, $2, $3)
		RETURNING id, trip_id, name, linked_itinerary_day, created_at, updated_at
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, d.TripID, d.Name, d.LinkedItineraryDay)
	res, err := repo.scanDay(row)
	if err != nil {
		return nil, fmt.Errorf("create meal plan day: %w", err)
	}
	return res, nil
}

func (repo *tripMealPlanDayRepository) Update(ctx context.Context, d *MealPlanDay) (*MealPlanDay, error) {
	query := `
		UPDATE trip_meal_plan_days
		SET name = $1, linked_itinerary_day = $2, updated_at = NOW()
		WHERE id = $3 AND trip_id = $4
		RETURNING id, trip_id, name, linked_itinerary_day, created_at, updated_at
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, d.Name, d.LinkedItineraryDay, d.ID, d.TripID)
	res, err := repo.scanDay(row)
	if err != nil {
		return nil, fmt.Errorf("update meal plan day: %w", err)
	}
	return res, nil
}

func (repo *tripMealPlanDayRepository) Delete(ctx context.Context, id string, tripID string) error {
	query := `
		DELETE FROM trip_meal_plan_days
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	_, err := db.Exec(ctx, query, id, tripID)
	if err != nil {
		return fmt.Errorf("delete meal plan day %s in trip %s: %w", id, tripID, err)
	}
	return nil
}

func (repo *tripMealPlanDayRepository) GetByID(ctx context.Context, id string, tripID string) (*MealPlanDay, error) {
	query := `
		SELECT id, trip_id, name, linked_itinerary_day, created_at, updated_at
		FROM trip_meal_plan_days
		WHERE id = $1 AND trip_id = $2
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, id, tripID)
	res, err := repo.scanDay(row)
	if err != nil {
		return nil, fmt.Errorf("get meal plan day: %w", err)
	}
	return res, nil
}

func (repo *tripMealPlanDayRepository) ReplaceAll(ctx context.Context, tripID string, days []*MealPlanDay) error {
	db := database.GetQuerier(ctx, repo.pool)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, repo.pool, func(txCtx context.Context) error {
			return repo.ReplaceAll(txCtx, tripID, days)
		})
	}

	_, err := tx.Exec(ctx, "DELETE FROM trip_meal_plan_days WHERE trip_id = $1", tripID)
	if err != nil {
		return fmt.Errorf("replace all meal plan days (delete phase) for trip %s: %w", tripID, err)
	}

	query := `
		INSERT INTO trip_meal_plan_days (id, trip_id, name, linked_itinerary_day, created_at, updated_at)
		VALUES ($1, $2, $3, $4, COALESCE($5, NOW()), COALESCE($6, NOW()))
	`
	for _, d := range days {
		_, err := tx.Exec(ctx, query,
			d.ID, tripID, d.Name, d.LinkedItineraryDay, d.CreatedAt, d.UpdatedAt,
		)
		if err != nil {
			return fmt.Errorf("replace all meal plan days (insert phase) item %s for trip %s: %w", d.ID, tripID, err)
		}
	}

	return nil
}

func (repo *tripMealPlanDayRepository) scanDay(row pgx.Row) (*MealPlanDay, error) {
	var d MealPlanDay
	err := row.Scan(
		&d.ID, &d.TripID, &d.Name, &d.LinkedItineraryDay,
		&d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}
