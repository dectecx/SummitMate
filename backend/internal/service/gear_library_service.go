package service

import (
	"context"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type GearLibraryService struct {
	repo *repository.GearLibraryRepository
}

func NewGearLibraryService(repo *repository.GearLibraryRepository) *GearLibraryService {
	return &GearLibraryService{repo: repo}
}

func (s *GearLibraryService) CreateItem(ctx context.Context, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	req.UserID = userID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	return s.repo.Create(ctx, req)
}

func (s *GearLibraryService) GetItem(ctx context.Context, itemID, userID string) (*model.GearLibraryItem, error) {
	return s.repo.GetByID(ctx, itemID, userID)
}

func (s *GearLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool) ([]*model.GearLibraryItem, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived)
}

func (s *GearLibraryService) UpdateItem(ctx context.Context, itemID, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error) {
	req.ID = itemID
	req.UserID = userID
	req.UpdatedBy = userID
	return s.repo.Update(ctx, req)
}

func (s *GearLibraryService) DeleteItem(ctx context.Context, itemID, userID string) error {
	return s.repo.Delete(ctx, itemID, userID)
}
