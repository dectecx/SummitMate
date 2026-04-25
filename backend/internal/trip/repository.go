package trip

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"

	"summitmate/internal/database"
)

// ErrNotFound 代表查詢結果為空 (無符合條件的資料列)。
var ErrNotFound = errors.New("not found")

// TripRepository 定義行程資料存取介面。
type TripRepository interface {
	Create(ctx context.Context, trip *Trip) (*Trip, error)
	GetByID(ctx context.Context, id string) (*Trip, error)
	ListByUserID(ctx context.Context, userID string, page int, limit int, search string) ([]*Trip, int, bool, error)
	Update(ctx context.Context, trip *Trip, lastUpdatedAt *time.Time) (*Trip, error)
	DeleteByID(ctx context.Context, id string) error
}

type tripRepository struct {
	db database.Querier
}

func NewTripRepository(db database.Querier) TripRepository {
	return &tripRepository{db: db}
}

// Create 新增一筆行程資料，回傳含有 DB 產生值 (id, created_at 等) 的完整 Trip。
func (repo *tripRepository) Create(ctx context.Context, trip *Trip) (*Trip, error) {
	query := `
		INSERT INTO trips (user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query,
		trip.UserID, trip.Name, trip.Description, trip.StartDate, trip.EndDate,
		trip.CoverImage, trip.IsActive, trip.DayNames, trip.CreatedBy, trip.UpdatedBy,
	)

	t, err := repo.scanTrip(row)
	if err != nil {
		return nil, fmt.Errorf("create trip: %w", err)
	}
	return t, nil
}

// GetByID 以 UUID 查詢行程。若不存在回傳 ErrNotFound。
func (repo *tripRepository) GetByID(ctx context.Context, id string) (*Trip, error) {
	query := `
		SELECT id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by
		FROM trips
		WHERE id = $1
	`
	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query, id)
	t, err := repo.scanTrip(row)
	if err != nil {
		return nil, fmt.Errorf("get trip %s: %w", id, err)
	}
	return t, nil
}

// ListByUserID 取得特定使用者建立或加入的行程列表，支援頁碼分頁與搜尋。
func (repo *tripRepository) ListByUserID(ctx context.Context, userID string, page int, limit int, search string) ([]*Trip, int, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	args := []interface{}{userID}
	argIdx := 2

	// 構建過濾條件子句
	whereClause := "WHERE (t.user_id = $1 OR tm.user_id = $1)"
	if search != "" {
		whereClause += fmt.Sprintf(" AND t.name ILIKE $%d", argIdx)
		args = append(args, "%"+search+"%")
		argIdx++
	}

	// COUNT 查詢
	countQuery := fmt.Sprintf(`
		SELECT COUNT(DISTINCT t.id)
		FROM trips t
		LEFT JOIN trip_members tm ON t.id = tm.trip_id
		%s
	`, whereClause)

	db := database.GetQuerier(ctx, repo.db)
	var total int
	err := db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, false, fmt.Errorf("count trips by user %s: %w", userID, err)
	}

	dataArgs := append(args, limit+1, offset)
	limitIdx := argIdx
	offsetIdx := argIdx + 1

	mainQuery := fmt.Sprintf(`
		WITH TargetPageIDs AS (
			SELECT DISTINCT t.id
			FROM trips t
			LEFT JOIN trip_members tm ON t.id = tm.trip_id
			%s
			ORDER BY t.created_at DESC, t.id ASC
			LIMIT $%d OFFSET $%d
		)
		SELECT t.id, t.user_id, t.name, t.description, t.start_date, t.end_date,
			t.cover_image, t.is_active, t.day_names,
			t.created_at, t.created_by, t.updated_at, t.updated_by
		FROM trips t
		INNER JOIN TargetPageIDs target ON t.id = target.id
		ORDER BY t.created_at DESC, t.id ASC
	`, whereClause, limitIdx, offsetIdx)

	rows, err := db.Query(ctx, mainQuery, dataArgs...)
	if err != nil {
		return nil, 0, false, fmt.Errorf("query trips by user %s: %w", userID, err)
	}
	defer rows.Close()

	var trips []*Trip
	for rows.Next() {
		var t Trip
		err := rows.Scan(
			&t.ID, &t.UserID, &t.Name, &t.Description, &t.StartDate, &t.EndDate,
			&t.CoverImage, &t.IsActive, &t.DayNames,
			&t.CreatedAt, &t.CreatedBy, &t.UpdatedAt, &t.UpdatedBy,
		)
		if err != nil {
			return nil, 0, false, fmt.Errorf("scan trip row: %w", err)
		}
		trips = append(trips, &t)
	}

	if err := rows.Err(); err != nil {
		return nil, 0, false, fmt.Errorf("iterate trip rows: %w", err)
	}

	hasMore := page*limit < total
	return trips, total, hasMore, nil
}

// Update 更新行程資料，必須提供 tripId，並僅更新允許修改的欄位。
// 如果提供了 lastUpdatedAt，則會檢查資料庫中的 updated_at 是否相符 (樂觀鎖)。
func (repo *tripRepository) Update(ctx context.Context, trip *Trip, lastUpdatedAt *time.Time) (*Trip, error) {
	query := `
		UPDATE trips
		SET name = $1, description = $2, start_date = $3, end_date = $4, cover_image = $5, is_active = $6, day_names = $7, updated_at = NOW(), updated_by = $8
		WHERE id = $9
	`

	args := []interface{}{
		trip.Name, trip.Description, trip.StartDate, trip.EndDate,
		trip.CoverImage, trip.IsActive, trip.DayNames, trip.UpdatedBy, trip.ID,
	}

	if lastUpdatedAt != nil {
		query += " AND updated_at = $10"
		args = append(args, *lastUpdatedAt)
	}

	query += " RETURNING id, user_id, name, description, start_date, end_date, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by"

	db := database.GetQuerier(ctx, repo.db)
	row := db.QueryRow(ctx, query, args...)

	t, err := repo.scanTrip(row)
	if err != nil {
		return nil, fmt.Errorf("update trip %s: %w", trip.ID, err)
	}
	return t, nil
}

// DeleteByID 刪除指定 ID 的行程。
func (repo *tripRepository) DeleteByID(ctx context.Context, id string) error {
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, "DELETE FROM trips WHERE id = $1", id)
	if err != nil {
		return fmt.Errorf("delete trip %s: %w", id, err)
	}
	return nil
}

// scanTrip 是共用掃描行列輔助函式。
func (repo *tripRepository) scanTrip(row pgx.Row) (*Trip, error) {
	var t Trip
	err := row.Scan(
		&t.ID, &t.UserID, &t.Name, &t.Description, &t.StartDate, &t.EndDate,
		&t.CoverImage, &t.IsActive, &t.DayNames,
		&t.CreatedAt, &t.CreatedBy, &t.UpdatedAt, &t.UpdatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("scan trip: %w", err)
	}
	return &t, nil
}
