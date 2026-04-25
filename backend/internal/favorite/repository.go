package favorite

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

type BatchFavoriteItem struct {
	TargetID   string
	Type       string
	IsFavorite bool
}

type FavoriteRepository interface {
	ListByUserID(ctx context.Context, userID string) ([]*Favorite, error)
	Create(ctx context.Context, fav *Favorite) error
	DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error
	BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error
}

type favoriteRepository struct {
	db database.DB
}

func NewFavoriteRepository(db database.DB) FavoriteRepository {
	return &favoriteRepository{db: db}
}

func (r *favoriteRepository) ListByUserID(ctx context.Context, userID string) ([]*Favorite, error) {
	query := `SELECT id, user_id, target_id, type, created_at, created_by, updated_at, updated_by FROM favorites WHERE user_id = $1 ORDER BY created_at DESC`
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("list favorites for user %s: %w", userID, err)
	}
	defer rows.Close()

	var favs []*Favorite
	for rows.Next() {
		var f Favorite
		if err := rows.Scan(&f.ID, &f.UserID, &f.TargetID, &f.Type, &f.CreatedAt, &f.CreatedBy, &f.UpdatedAt, &f.UpdatedBy); err != nil {
			return nil, fmt.Errorf("scan favorite row: %w", err)
		}
		favs = append(favs, &f)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate favorite rows: %w", err)
	}
	return favs, nil
}

func (r *favoriteRepository) Create(ctx context.Context, fav *Favorite) error {
	query := `
		INSERT INTO favorites (user_id, target_id, type, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`
	db := database.GetQuerier(ctx, r.db)
	err := db.QueryRow(ctx, query, fav.UserID, fav.TargetID, fav.Type, fav.CreatedBy, fav.UpdatedBy).Scan(&fav.ID, &fav.CreatedAt, &fav.UpdatedAt)
	if err != nil {
		return fmt.Errorf("create favorite for user %s on target %s: %w", fav.UserID, fav.TargetID, err)
	}
	return nil
}

func (r *favoriteRepository) DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error {
	query := `DELETE FROM favorites WHERE target_id = $1 AND user_id = $2`
	db := database.GetQuerier(ctx, r.db)
	cmd, err := db.Exec(ctx, query, targetID, userID)
	if err != nil {
		return fmt.Errorf("delete favorite for user %s on target %s: %w", userID, targetID, err)
	}
	if cmd.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *favoriteRepository) BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			return r.BatchUpdate(txCtx, userID, items)
		})
	}

	for _, item := range items {
		if item.IsFavorite {
			query := `
				INSERT INTO favorites (user_id, target_id, type, created_by, updated_by)
				VALUES ($1, $2, $3, $4, $5)
				ON CONFLICT (user_id, target_id) DO NOTHING
			`
			_, err := tx.Exec(ctx, query, userID, item.TargetID, item.Type, userID, userID)
			if err != nil {
				return fmt.Errorf("batch insert favorite for user %s on target %s: %w", userID, item.TargetID, err)
			}
		} else {
			query := `DELETE FROM favorites WHERE target_id = $1 AND user_id = $2`
			_, err := tx.Exec(ctx, query, item.TargetID, userID)
			if err != nil {
				return fmt.Errorf("batch delete favorite for user %s on target %s: %w", userID, item.TargetID, err)
			}
		}
	}

	return nil
}
