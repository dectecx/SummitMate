package service

import (
	"context"
	"log/slog"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type MealLibraryService struct {
	logger *slog.Logger
	repo   repository.MealLibraryRepository
}

func NewMealLibraryService(logger *slog.Logger, repo repository.MealLibraryRepository) *MealLibraryService {
	return &MealLibraryService{
		logger: logger.With("component", "meal_library"),
		repo:   repo,
	}
}

func (s *MealLibraryService) CreateItem(ctx context.Context, userID string, req *model.MealLibraryItem) (*model.MealLibraryItem, error) {
	req.UserID = userID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	item, err := s.repo.Create(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立食譜庫項目失敗", "user_id", userID, "name", req.Name, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "食譜庫項目建立成功", "item_id", item.ID, "user_id", userID, "name", item.Name)
	return item, nil
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
	item, err := s.repo.Update(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "更新食譜庫項目失敗", "item_id", itemID, "user_id", userID, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "食譜庫項目更新成功", "item_id", itemID, "user_id", userID)
	return item, nil
}

func (s *MealLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*model.MealLibraryItem) error {
	for _, item := range items {
		item.UserID = userID
		if item.CreatedBy == "" {
			item.CreatedBy = userID
		}
		item.UpdatedBy = userID
	}
	return s.repo.ReplaceAll(ctx, userID, items)
}

func (s *MealLibraryService) DeleteItem(ctx context.Context, itemID, userID string) error {
	if err := s.repo.Delete(ctx, itemID, userID); err != nil {
		s.logger.ErrorContext(ctx, "刪除食譜庫項目失敗", "item_id", itemID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "食譜庫項目刪除成功", "item_id", itemID, "user_id", userID)
	return nil
}
