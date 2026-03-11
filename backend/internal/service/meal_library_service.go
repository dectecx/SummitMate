package service

import (
	"context"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type MealLibraryService struct {
	repo *repository.MealLibraryRepository
}

func NewMealLibraryService(repo *repository.MealLibraryRepository) *MealLibraryService {
	return &MealLibraryService{repo: repo}
}

func (s *MealLibraryService) CreateItem(ctx context.Context, userID string, req *model.MealLibraryItem) (*model.MealLibraryItem, error) {
	req.UserID = userID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	return s.repo.Create(ctx, req)
}

func (s *MealLibraryService) GetItem(ctx context.Context, itemID, userID string) (*model.MealLibraryItem, error) {
	return s.repo.GetByID(ctx, itemID, userID)
}

func (s *MealLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool) ([]*model.MealLibraryItem, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived)
}

func (s *MealLibraryService) UpdateItem(ctx context.Context, itemID, userID string, req *model.MealLibraryItem) (*model.MealLibraryItem, error) {
	req.ID = itemID
	req.UserID = userID
	req.UpdatedBy = userID
	return s.repo.Update(ctx, req)
}

func (s *MealLibraryService) DeleteItem(ctx context.Context, itemID, userID string) error {
	return s.repo.Delete(ctx, itemID, userID)
}
