package service

import (
	"context"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type FavoriteService struct {
	repo repository.FavoriteRepository
}

func NewFavoriteService(repo repository.FavoriteRepository) *FavoriteService {
	return &FavoriteService{repo: repo}
}

func (s *FavoriteService) ListFavorites(ctx context.Context, userID string) ([]*model.Favorite, error) {
	return s.repo.ListByUserID(ctx, userID)
}

func (s *FavoriteService) AddFavorite(ctx context.Context, userID, targetID, favType string) (*model.Favorite, error) {
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

func (s *FavoriteService) RemoveFavorite(ctx context.Context, targetID, userID string) error {
	return s.repo.DeleteByTargetAndUser(ctx, targetID, userID)
}
