package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

// TripRepository 封裝 trips 表的資料庫存取操作。
type TripRepository struct {
	pool *pgxpool.Pool
}

// NewTripRepository 建立 TripRepository 實例。
func NewTripRepository(pool *pgxpool.Pool) *TripRepository {
	return &TripRepository{pool: pool}
}

// Create 新增一筆行程資料，回傳含有 DB 產生值 (id, created_at 等) 的完整 Trip。
func (repo *TripRepository) Create(ctx context.Context, trip *model.Trip) (*model.Trip, error) {
	query := `
		INSERT INTO trips (user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		trip.UserID, trip.Name, trip.Description, trip.StartDate, trip.EndDate,
		trip.CoverImage, trip.IsActive, trip.DayNames, trip.CreatedBy, trip.UpdatedBy,
	)

	return repo.scanTrip(row)
}

// GetByID 以 UUID 查詢行程。若不存在回傳 ErrNotFound。
func (repo *TripRepository) GetByID(ctx context.Context, id string) (*model.Trip, error) {
	query := `
		SELECT id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by
		FROM trips
		WHERE id = $1
	`
	row := repo.pool.QueryRow(ctx, query, id)
	return repo.scanTrip(row)
}

// ListByUserID 取得特定使用者建立或加入的行程列表。
// 這裡預期回傳包含 created 或是加入 trip_members 的所有行程。
func (repo *TripRepository) ListByUserID(ctx context.Context, userID string) ([]*model.Trip, error) {
	query := `
		SELECT DISTINCT t.id, t.user_id, t.name, t.description, t.start_date, t.end_date, t.cover_image, t.is_active, t.day_names, t.created_at, t.created_by, t.updated_at, t.updated_by
		FROM trips t
		LEFT JOIN trip_members tm ON t.id = tm.trip_id
		WHERE t.user_id = $1 OR tm.user_id = $1
		ORDER BY t.created_at DESC
	`
	rows, err := repo.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var trips []*model.Trip
	for rows.Next() {
		var t model.Trip
		err := rows.Scan(
			&t.ID, &t.UserID, &t.Name, &t.Description, &t.StartDate, &t.EndDate,
			&t.CoverImage, &t.IsActive, &t.DayNames,
			&t.CreatedAt, &t.CreatedBy, &t.UpdatedAt, &t.UpdatedBy,
		)
		if err != nil {
			return nil, err
		}
		trips = append(trips, &t)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return trips, nil
}

// Update 更新行程資料，必須提供 tripId，並僅更新允許修改的欄位。
func (repo *TripRepository) Update(ctx context.Context, trip *model.Trip) (*model.Trip, error) {
	query := `
		UPDATE trips
		SET name = $1, description = $2, start_date = $3, end_date = $4, cover_image = $5, is_active = $6, day_names = $7, updated_at = NOW(), updated_by = $8
		WHERE id = $9
		RETURNING id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by
	`
	row := repo.pool.QueryRow(ctx, query,
		trip.Name, trip.Description, trip.StartDate, trip.EndDate,
		trip.CoverImage, trip.IsActive, trip.DayNames, trip.UpdatedBy, trip.ID,
	)

	return repo.scanTrip(row)
}

// DeleteByID 刪除指定 ID 的行程。
func (repo *TripRepository) DeleteByID(ctx context.Context, id string) error {
	_, err := repo.pool.Exec(ctx, "DELETE FROM trips WHERE id = $1", id)
	return err
}

// scanTrip 是共用掃描行列輔助函式。
func (repo *TripRepository) scanTrip(row pgx.Row) (*model.Trip, error) {
	var t model.Trip
	err := row.Scan(
		&t.ID, &t.UserID, &t.Name, &t.Description, &t.StartDate, &t.EndDate,
		&t.CoverImage, &t.IsActive, &t.DayNames,
		&t.CreatedAt, &t.CreatedBy, &t.UpdatedAt, &t.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &t, nil
}
