package favorite

import (
	"context"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/database"
)

// FavoriteService 定義我的最愛相關的業務邏輯介面。
type FavoriteService interface {
	ListFavorites(ctx context.Context, userID string, page int, limit int) ([]*Favorite, int, bool, error)
	AddFavorite(ctx context.Context, userID, targetID, favType string) (*Favorite, error)
	RemoveFavorite(ctx context.Context, targetID, userID, favType string) error
	BatchUpdateFavorites(ctx context.Context, userID string, items []BatchFavoriteItem) error
}

type favoriteService struct {
	logger *slog.Logger
	db     database.Beginner
	repo   FavoriteRepository
}

func NewFavoriteService(logger *slog.Logger, db database.Beginner, repo FavoriteRepository) FavoriteService {
	return &favoriteService{
		logger: logger.With("component", "favorite"),
		db:     db,
		repo:   repo,
	}
}

func (s *favoriteService) ListFavorites(ctx context.Context, userID string, page int, limit int) ([]*Favorite, int, bool, error) {
	return s.repo.ListByUserID(ctx, userID, page, limit)
}

func (s *favoriteService) AddFavorite(ctx context.Context, userID, targetID, favType string) (*Favorite, error) {
	if !IsValidType(favType) {
		return nil, apperror.ErrInvalidFavoriteType
	}
	fav := &Favorite{
		UserID:    userID,
		TargetID:  targetID,
		Type:      favType,
		CreatedBy: userID,
		UpdatedBy: userID,
	}
	if err := s.repo.Create(ctx, fav); err != nil {
		return nil, err
	}
	return fav, nil
}

func (s *favoriteService) RemoveFavorite(ctx context.Context, targetID, userID, favType string) error {
	if !IsValidType(favType) {
		return apperror.ErrInvalidFavoriteType
	}
	return s.repo.DeleteByTargetAndUser(ctx, targetID, userID, favType)
}

func (s *favoriteService) BatchUpdateFavorites(ctx context.Context, userID string, items []BatchFavoriteItem) error {
	for _, item := range items {
		if !IsValidType(item.Type) {
			return apperror.ErrInvalidFavoriteType
		}
	}
	return database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
		return s.repo.BatchUpdate(txCtx, userID, items)
	})
}
