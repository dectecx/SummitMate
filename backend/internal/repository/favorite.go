package repository

import (
	"context"
	"fmt"

	"summitmate/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type BatchFavoriteItem struct {
	TargetID   string
	Type       string
	IsFavorite bool
}

type FavoriteRepository interface {
	ListByUserID(ctx context.Context, userID string) ([]*model.Favorite, error)
	Create(ctx context.Context, fav *model.Favorite) error
	DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error
	BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error
}

type favoriteRepository struct {
	db *pgxpool.Pool
}

func NewFavoriteRepository(db *pgxpool.Pool) FavoriteRepository {
	return &favoriteRepository{db: db}
}

func (r *favoriteRepository) ListByUserID(ctx context.Context, userID string) ([]*model.Favorite, error) {
	query := `SELECT id, user_id, target_id, type, created_at, created_by, updated_at, updated_by FROM favorites WHERE user_id = $1 ORDER BY created_at DESC`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list favorites: %w", err)
	}
	defer rows.Close()

	var favs []*model.Favorite
	for rows.Next() {
		var f model.Favorite
		if err := rows.Scan(&f.ID, &f.UserID, &f.TargetID, &f.Type, &f.CreatedAt, &f.CreatedBy, &f.UpdatedAt, &f.UpdatedBy); err != nil {
			return nil, err
		}
		favs = append(favs, &f)
	}
	return favs, rows.Err()
}

func (r *favoriteRepository) Create(ctx context.Context, fav *model.Favorite) error {
	query := `
		INSERT INTO favorites (user_id, target_id, type, created_by, updated_by)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query, fav.UserID, fav.TargetID, fav.Type, fav.CreatedBy, fav.UpdatedBy).Scan(&fav.ID, &fav.CreatedAt, &fav.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to create favorite: %w", err)
	}
	return nil
}

func (r *favoriteRepository) DeleteByTargetAndUser(ctx context.Context, targetID, userID string) error {
	query := `DELETE FROM favorites WHERE target_id = $1 AND user_id = $2`
	cmd, err := r.db.Exec(ctx, query, targetID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete favorite: %w", err)
	}
	if cmd.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *favoriteRepository) BatchUpdate(ctx context.Context, userID string, items []BatchFavoriteItem) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, item := range items {
		if item.IsFavorite {
			query := `
				INSERT INTO favorites (user_id, target_id, type, created_by, updated_by)
				VALUES ($1, $2, $3, $4, $5)
				ON CONFLICT (user_id, target_id) DO NOTHING
			`
			_, err := tx.Exec(ctx, query, userID, item.TargetID, item.Type, userID, userID)
			if err != nil {
				return err
			}
		} else {
			query := `DELETE FROM favorites WHERE target_id = $1 AND user_id = $2`
			_, err := tx.Exec(ctx, query, item.TargetID, userID)
			if err != nil {
				return err
			}
		}
	}

	return tx.Commit(ctx)
}
