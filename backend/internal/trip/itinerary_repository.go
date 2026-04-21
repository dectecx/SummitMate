package trip

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/database"
)

// ItineraryRepository 定義行程節點資料存取介面。
type ItineraryRepository interface {
	Create(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error)
	GetByID(ctx context.Context, id string) (*ItineraryItem, error)
	ListByTripID(ctx context.Context, tripID string) ([]*ItineraryItem, error)
	Update(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error)
	DeleteByID(ctx context.Context, id string) error
}

type itineraryRepository struct {
	pool *pgxpool.Pool
}

func NewItineraryRepository(pool *pgxpool.Pool) ItineraryRepository {
	return &itineraryRepository{pool: pool}
}

// Create 新增一筆行程表節點，回傳建立好的節點內容。
func (repo *itineraryRepository) Create(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	query := `
		INSERT INTO itinerary_items (trip_id, day, name, est_time, altitude, distance, note, image_asset, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, trip_id, day, name, est_time, actual_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.TripID, item.Day, item.Name, item.EstTime, item.Altitude, item.Distance,
		item.Note, item.ImageAsset, item.CreatedBy, item.UpdatedBy,
	)

	return repo.scanItem(row)
}

// GetByID 取得單一行程表節點資訊。
func (repo *itineraryRepository) GetByID(ctx context.Context, id string) (*ItineraryItem, error) {
	query := `
		SELECT id, trip_id, day, name, est_time, actual_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at, created_at, created_by, updated_at, updated_by
		FROM itinerary_items
		WHERE id = $1
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query, id)
	return repo.scanItem(row)
}

// ListByTripID 取得特定行程的所有行程表節點，通常依時間序與天數排列。
func (repo *itineraryRepository) ListByTripID(ctx context.Context, tripID string) ([]*ItineraryItem, error) {
	query := `
		SELECT id, trip_id, day, name, est_time, actual_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at, created_at, created_by, updated_at, updated_by
		FROM itinerary_items
		WHERE trip_id = $1
		ORDER BY day ASC, est_time ASC
	`
	db := database.GetQuerier(ctx, repo.pool)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*ItineraryItem
	for rows.Next() {
		var i ItineraryItem
		err := rows.Scan(
			&i.ID, &i.TripID, &i.Day, &i.Name, &i.EstTime, &i.ActualTime,
			&i.Altitude, &i.Distance, &i.Note, &i.ImageAsset, &i.IsCheckedIn,
			&i.CheckedInAt, &i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
		)
		if err != nil {
			return nil, err
		}
		items = append(items, &i)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

// Update 更新行程表節點的資料。
func (repo *itineraryRepository) Update(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	query := `
		UPDATE itinerary_items
		SET day = $1, name = $2, est_time = $3, actual_time = $4, altitude = $5, distance = $6, note = $7, image_asset = $8, is_checked_in = $9, checked_in_at = $10, updated_at = NOW(), updated_by = $11
		WHERE id = $12
		RETURNING id, trip_id, day, name, est_time, actual_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.pool)
	row := db.QueryRow(ctx, query,
		item.Day, item.Name, item.EstTime, item.ActualTime, item.Altitude, item.Distance,
		item.Note, item.ImageAsset, item.IsCheckedIn, item.CheckedInAt, item.UpdatedBy, item.ID,
	)

	return repo.scanItem(row)
}

// DeleteByID 刪除單一行程表節點。
func (repo *itineraryRepository) DeleteByID(ctx context.Context, id string) error {
	db := database.GetQuerier(ctx, repo.pool)
	_, err := db.Exec(ctx, "DELETE FROM itinerary_items WHERE id = $1", id)
	return err
}

// scanItem 是共用掃描行列輔助函式。
func (repo *itineraryRepository) scanItem(row pgx.Row) (*ItineraryItem, error) {
	var i ItineraryItem
	err := row.Scan(
		&i.ID, &i.TripID, &i.Day, &i.Name, &i.EstTime, &i.ActualTime,
		&i.Altitude, &i.Distance, &i.Note, &i.ImageAsset, &i.IsCheckedIn,
		&i.CheckedInAt, &i.CreatedAt, &i.CreatedBy, &i.UpdatedAt, &i.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &i, nil
}
