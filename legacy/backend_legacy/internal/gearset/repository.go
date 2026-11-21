package gearset

import (
	"context"
	"fmt"

	"summitmate/internal/database"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// GearSetRepository 定義裝備組合資料存取介面。
type GearSetRepository interface {
	Create(ctx context.Context, gs *GearSet) error
	GetByID(ctx context.Context, id uuid.UUID) (*GearSet, error)
	Delete(ctx context.Context, id uuid.UUID) error
	Update(ctx context.Context, gs *GearSet) error
	List(ctx context.Context, limit, offset int, search string, filter GearSetListFilter) ([]*GearSet, int, error)
}

type gearSetRepository struct {
	db database.DB
}

func NewGearSetRepository(db database.DB) GearSetRepository {
	return &gearSetRepository{db: db}
}

func (r *gearSetRepository) Create(ctx context.Context, gs *GearSet) error {
	return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
		db := database.GetQuerier(txCtx, r.db)

		query := `
			INSERT INTO gear_sets (
				id, title, author, total_weight, item_count, visibility, download_key,
				user_id, created_at, created_by, updated_at, updated_by
			) VALUES (
				$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
			)
		`
		_, err := db.Exec(txCtx, query,
			gs.ID, gs.Title, gs.Author, gs.TotalWeight, gs.ItemCount, gs.Visibility, gs.DownloadKey,
			gs.UserID, gs.CreatedAt, gs.CreatedBy, gs.UpdatedAt, gs.UpdatedBy,
		)
		if err != nil {
			return fmt.Errorf("failed to insert gear set: %w", err)
		}

		for _, item := range gs.Items {
			qItem := `INSERT INTO gear_set_items (id, gear_set_id, name, category, weight, quantity, order_index) VALUES ($1, $2, $3, $4, $5, $6, $7)`
			if item.ID == uuid.Nil {
				item.ID = uuid.Must(uuid.NewV7())
			}
			_, err = db.Exec(txCtx, qItem, item.ID, gs.ID, item.Name, item.Category, item.Weight, item.Quantity, item.OrderIndex)
			if err != nil {
				return fmt.Errorf("failed to insert gear set item: %w", err)
			}
		}

		for _, meal := range gs.Meals {
			qMeal := `INSERT INTO gear_set_meals (id, gear_set_id, day, meal_type, name, calories, note) VALUES ($1, $2, $3, $4, $5, $6, $7)`
			if meal.ID == uuid.Nil {
				meal.ID = uuid.Must(uuid.NewV7())
			}
			_, err = db.Exec(txCtx, qMeal, meal.ID, gs.ID, meal.Day, meal.MealType, meal.Name, meal.Calories, meal.Note)
			if err != nil {
				return fmt.Errorf("failed to insert gear set meal: %w", err)
			}
		}

		return nil
	})
}

func (r *gearSetRepository) GetByID(ctx context.Context, id uuid.UUID) (*GearSet, error) {
	query := `
		SELECT id, title, author, total_weight, item_count, visibility, download_key,
			   user_id, created_at, created_by, updated_at, updated_by
		FROM gear_sets
		WHERE id = $1
	`
	db := database.GetQuerier(ctx, r.db)
	var gs GearSet
	err := db.QueryRow(ctx, query, id).Scan(
		&gs.ID, &gs.Title, &gs.Author, &gs.TotalWeight, &gs.ItemCount, &gs.Visibility, &gs.DownloadKey,
		&gs.UserID, &gs.CreatedAt, &gs.CreatedBy, &gs.UpdatedAt, &gs.UpdatedBy,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("gear set not found: %w", err)
		}
		return nil, fmt.Errorf("failed to get gear set: %w", err)
	}

	qItems := `SELECT id, gear_set_id, name, category, weight, quantity, order_index FROM gear_set_items WHERE gear_set_id = $1 ORDER BY order_index ASC`
	rows, err := db.Query(ctx, qItems, id)
	if err != nil {
		return nil, fmt.Errorf("failed to query gear set items: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var it GearSetItem
		if err := rows.Scan(&it.ID, &it.GearSetID, &it.Name, &it.Category, &it.Weight, &it.Quantity, &it.OrderIndex); err != nil {
			return nil, fmt.Errorf("failed to scan gear set item: %w", err)
		}
		gs.Items = append(gs.Items, it)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed to iterate gear set items: %w", err)
	}

	qMeals := `SELECT id, gear_set_id, day, meal_type, name, calories, note FROM gear_set_meals WHERE gear_set_id = $1`
	mrows, err := db.Query(ctx, qMeals, id)
	if err != nil {
		return nil, fmt.Errorf("failed to query gear set meals: %w", err)
	}
	defer mrows.Close()

	for mrows.Next() {
		var m GearSetMeal
		if err := mrows.Scan(&m.ID, &m.GearSetID, &m.Day, &m.MealType, &m.Name, &m.Calories, &m.Note); err != nil {
			return nil, fmt.Errorf("failed to scan gear set meal: %w", err)
		}
		gs.Meals = append(gs.Meals, m)
	}
	if err := mrows.Err(); err != nil {
		return nil, fmt.Errorf("failed to iterate gear set meals: %w", err)
	}

	return &gs, nil
}

func (r *gearSetRepository) Update(ctx context.Context, gs *GearSet) error {
	return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
		db := database.GetQuerier(txCtx, r.db)

		query := `
			UPDATE gear_sets SET
				title = $1, author = $2, total_weight = $3, item_count = $4,
				visibility = $5, download_key = $6, updated_at = $7, updated_by = $8
			WHERE id = $9
		`
		_, err := db.Exec(txCtx, query,
			gs.Title, gs.Author, gs.TotalWeight, gs.ItemCount, gs.Visibility, gs.DownloadKey,
			gs.UpdatedAt, gs.UpdatedBy, gs.ID,
		)
		if err != nil {
			return fmt.Errorf("failed to update gear set: %w", err)
		}

		// Delete old items and meals
		_, err = db.Exec(txCtx, `DELETE FROM gear_set_items WHERE gear_set_id = $1`, gs.ID)
		if err != nil {
			return fmt.Errorf("failed to delete old gear set items: %w", err)
		}
		_, err = db.Exec(txCtx, `DELETE FROM gear_set_meals WHERE gear_set_id = $1`, gs.ID)
		if err != nil {
			return fmt.Errorf("failed to delete old gear set meals: %w", err)
		}

		// Insert new items
		for _, item := range gs.Items {
			qItem := `INSERT INTO gear_set_items (id, gear_set_id, name, category, weight, quantity, order_index) VALUES ($1, $2, $3, $4, $5, $6, $7)`
			if item.ID == uuid.Nil {
				item.ID = uuid.Must(uuid.NewV7())
			}
			_, err = db.Exec(txCtx, qItem, item.ID, gs.ID, item.Name, item.Category, item.Weight, item.Quantity, item.OrderIndex)
			if err != nil {
				return fmt.Errorf("failed to insert gear set item: %w", err)
			}
		}

		// Insert new meals
		for _, meal := range gs.Meals {
			qMeal := `INSERT INTO gear_set_meals (id, gear_set_id, day, meal_type, name, calories, note) VALUES ($1, $2, $3, $4, $5, $6, $7)`
			if meal.ID == uuid.Nil {
				meal.ID = uuid.Must(uuid.NewV7())
			}
			_, err = db.Exec(txCtx, qMeal, meal.ID, gs.ID, meal.Day, meal.MealType, meal.Name, meal.Calories, meal.Note)
			if err != nil {
				return fmt.Errorf("failed to insert gear set meal: %w", err)
			}
		}

		return nil
	})
}

func (r *gearSetRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM gear_sets WHERE id = $1`
	db := database.GetQuerier(ctx, r.db)
	res, err := db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete gear set: %w", err)
	}
	if res.RowsAffected() == 0 {
		return fmt.Errorf("gear set not found")
	}
	return nil
}

func (r *gearSetRepository) List(ctx context.Context, limit, offset int, search string, filter GearSetListFilter) ([]*GearSet, int, error) {
	baseQuery := `
		FROM gear_sets
		WHERE 1=1
	`
	args := []interface{}{}
	argIdx := 1

	if filter.OwnerID != nil {
		baseQuery += fmt.Sprintf(" AND user_id = $%d", argIdx)
		args = append(args, *filter.OwnerID)
		argIdx++
	}

	if len(filter.Visibilities) > 0 {
		placeholders := ""
		for i, v := range filter.Visibilities {
			if i > 0 {
				placeholders += ", "
			}
			placeholders += fmt.Sprintf("$%d", argIdx)
			args = append(args, string(v))
			argIdx++
		}
		baseQuery += fmt.Sprintf(" AND visibility IN (%s)", placeholders)
	}

	if search != "" {
		baseQuery += fmt.Sprintf(" AND (title ILIKE $%d OR author ILIKE $%d)", argIdx, argIdx)
		searchPattern := "%" + search + "%"
		args = append(args, searchPattern)
		argIdx++
	}

	db := database.GetQuerier(ctx, r.db)
	countQuery := "SELECT COUNT(*) " + baseQuery
	var total int
	err := db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count gear sets: %w", err)
	}

	selectQuery := `
		SELECT id, title, author, total_weight, item_count, visibility, download_key,
			   user_id, created_at, created_by, updated_at, updated_by
	` + baseQuery + fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)

	args = append(args, limit, offset)

	rows, err := db.Query(ctx, selectQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list gear sets: %w", err)
	}
	defer rows.Close()

	var sets []*GearSet
	for rows.Next() {
		var gs GearSet
		err := rows.Scan(
			&gs.ID, &gs.Title, &gs.Author, &gs.TotalWeight, &gs.ItemCount, &gs.Visibility, &gs.DownloadKey,
			&gs.UserID, &gs.CreatedAt, &gs.CreatedBy, &gs.UpdatedAt, &gs.UpdatedBy,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan gear set: %w", err)
		}
		sets = append(sets, &gs)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("failed to iterate gear sets: %w", err)
	}

	if len(sets) == 0 {
		return sets, total, nil
	}

	// Collect IDs for batch queries
	setIDs := make([]uuid.UUID, len(sets))
	setMap := make(map[uuid.UUID]*GearSet, len(sets))
	for i, gs := range sets {
		setIDs[i] = gs.ID
		setMap[gs.ID] = gs
	}

	// Batch load items
	iRows, err := db.Query(ctx,
		`SELECT id, gear_set_id, name, category, weight, quantity, order_index
		 FROM gear_set_items WHERE gear_set_id = ANY($1) ORDER BY gear_set_id, order_index ASC`,
		setIDs,
	)
	if err != nil {
		return nil, 0, fmt.Errorf("batch query gear set items: %w", err)
	}
	defer iRows.Close()

	for iRows.Next() {
		var it GearSetItem
		if err := iRows.Scan(&it.ID, &it.GearSetID, &it.Name, &it.Category, &it.Weight, &it.Quantity, &it.OrderIndex); err != nil {
			return nil, 0, fmt.Errorf("scan gear set item row: %w", err)
		}
		if gs, ok := setMap[it.GearSetID]; ok {
			gs.Items = append(gs.Items, it)
		}
	}
	if err := iRows.Err(); err != nil {
		return nil, 0, fmt.Errorf("iterate gear set item rows: %w", err)
	}

	// Batch load meals
	mRows, err := db.Query(ctx,
		`SELECT id, gear_set_id, day, meal_type, name, calories, note
		 FROM gear_set_meals WHERE gear_set_id = ANY($1)`,
		setIDs,
	)
	if err != nil {
		return nil, 0, fmt.Errorf("batch query gear set meals: %w", err)
	}
	defer mRows.Close()

	for mRows.Next() {
		var m GearSetMeal
		if err := mRows.Scan(&m.ID, &m.GearSetID, &m.Day, &m.MealType, &m.Name, &m.Calories, &m.Note); err != nil {
			return nil, 0, fmt.Errorf("scan gear set meal row: %w", err)
		}
		if gs, ok := setMap[m.GearSetID]; ok {
			gs.Meals = append(gs.Meals, m)
		}
	}
	if err := mRows.Err(); err != nil {
		return nil, 0, fmt.Errorf("iterate gear set meal rows: %w", err)
	}

	return sets, total, nil
}
