package service

import (
	"context"
	"log/slog"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

// FavoriteService 定義我的最愛相關的業務邏輯介面。
type FavoriteService interface {
	ListFavorites(ctx context.Context, userID string) ([]*model.Favorite, error)
	AddFavorite(ctx context.Context, userID, targetID, favType string) (*model.Favorite, error)
	RemoveFavorite(ctx context.Context, targetID, userID string) error
	BatchUpdateFavorites(ctx context.Context, userID string, items []repository.BatchFavoriteItem) error
}

type favoriteService struct {
	logger *slog.Logger
	repo   repository.FavoriteRepository
}

func NewFavoriteService(logger *slog.Logger, repo repository.FavoriteRepository) FavoriteService {
	return &favoriteService{
		logger: logger.With("component", "favorite"),
		repo:   repo,
	}
}

func (s *favoriteService) ListFavorites(ctx context.Context, userID string) ([]*model.Favorite, error) {
	return s.repo.ListByUserID(ctx, userID)
}

func (s *favoriteService) AddFavorite(ctx context.Context, userID, targetID, favType string) (*model.Favorite, error) {
	fav := &model.Favorite{
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

func (s *favoriteService) RemoveFavorite(ctx context.Context, targetID, userID string) error {
	return s.repo.DeleteByTargetAndUser(ctx, targetID, userID)
}

func (s *favoriteService) BatchUpdateFavorites(ctx context.Context, userID string, items []repository.BatchFavoriteItem) error {
	return s.repo.BatchUpdate(ctx, userID, items)
}
