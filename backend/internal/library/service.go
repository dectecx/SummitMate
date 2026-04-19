package library

import (
	"context"
	"log/slog"
)

// GearLibraryService 定義裝備庫相關的業務邏輯介面。
type GearLibraryService interface {
	CreateItem(ctx context.Context, userID string, req *GearLibraryItem) (*GearLibraryItem, error)
	GetItem(ctx context.Context, itemID, userID string) (*GearLibraryItem, error)
	ListItems(ctx context.Context, userID string, includeArchived bool) ([]*GearLibraryItem, error)
	UpdateItem(ctx context.Context, itemID, userID string, req *GearLibraryItem) (*GearLibraryItem, error)
	ReplaceAllItems(ctx context.Context, userID string, items []*GearLibraryItem) error
	DeleteItem(ctx context.Context, itemID, userID string) error
}

type gearLibraryService struct {
	logger *slog.Logger
	repo   GearLibraryRepository
}

func NewGearLibraryService(logger *slog.Logger, repo GearLibraryRepository) GearLibraryService {
	return &gearLibraryService{
		logger: logger.With("component", "gear_library"),
		repo:   repo,
	}
}

func (s *gearLibraryService) CreateItem(ctx context.Context, userID string, req *GearLibraryItem) (*GearLibraryItem, error) {
	req.UserID = userID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	item, err := s.repo.Create(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立裝備庫項目失敗", "user_id", userID, "name", req.Name, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "裝備庫項目建立成功", "item_id", item.ID, "user_id", userID, "name", item.Name)
	return item, nil
}

func (s *gearLibraryService) GetItem(ctx context.Context, itemID, userID string) (*GearLibraryItem, error) {
	return s.repo.GetByID(ctx, itemID, userID)
}

func (s *gearLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool) ([]*GearLibraryItem, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived)
}

func (s *gearLibraryService) UpdateItem(ctx context.Context, itemID, userID string, req *GearLibraryItem) (*GearLibraryItem, error) {
	req.ID = itemID
	req.UserID = userID
	req.UpdatedBy = userID
	item, err := s.repo.Update(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "更新裝備庫項目失敗", "item_id", itemID, "user_id", userID, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "裝備庫項目更新成功", "item_id", itemID, "user_id", userID)
	return item, nil
}

func (s *gearLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*GearLibraryItem) error {
	for _, item := range items {
		item.UserID = userID
		if item.CreatedBy == "" {
			item.CreatedBy = userID
		}
		item.UpdatedBy = userID
	}
	return s.repo.ReplaceAll(ctx, userID, items)
}

func (s *gearLibraryService) DeleteItem(ctx context.Context, itemID, userID string) error {
	if err := s.repo.Delete(ctx, itemID, userID); err != nil {
		s.logger.ErrorContext(ctx, "刪除裝備庫項目失敗", "item_id", itemID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "裝備庫項目刪除成功", "item_id", itemID, "user_id", userID)
	return nil
}

// MealLibraryService 定義食譜庫相關的業務邏輯介面。
type MealLibraryService interface {
	CreateItem(ctx context.Context, userID string, req *MealLibraryItem) (*MealLibraryItem, error)
	GetItem(ctx context.Context, itemID, userID string) (*MealLibraryItem, error)
	ListItems(ctx context.Context, userID string, includeArchived bool) ([]*MealLibraryItem, error)
	UpdateItem(ctx context.Context, itemID, userID string, req *MealLibraryItem) (*MealLibraryItem, error)
	ReplaceAllItems(ctx context.Context, userID string, items []*MealLibraryItem) error
	DeleteItem(ctx context.Context, itemID, userID string) error
}

type mealLibraryService struct {
	logger *slog.Logger
	repo   MealLibraryRepository
}

func NewMealLibraryService(logger *slog.Logger, repo MealLibraryRepository) MealLibraryService {
	return &mealLibraryService{
		logger: logger.With("component", "meal_library"),
		repo:   repo,
	}
}

func (s *mealLibraryService) CreateItem(ctx context.Context, userID string, req *MealLibraryItem) (*MealLibraryItem, error) {
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

func (s *mealLibraryService) GetItem(ctx context.Context, itemID, userID string) (*MealLibraryItem, error) {
	return s.repo.GetByID(ctx, itemID, userID)
}

func (s *mealLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool) ([]*MealLibraryItem, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived)
}

func (s *mealLibraryService) UpdateItem(ctx context.Context, itemID, userID string, req *MealLibraryItem) (*MealLibraryItem, error) {
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

func (s *mealLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*MealLibraryItem) error {
	for _, item := range items {
		item.UserID = userID
		if item.CreatedBy == "" {
			item.CreatedBy = userID
		}
		item.UpdatedBy = userID
	}
	return s.repo.ReplaceAll(ctx, userID, items)
}

func (s *mealLibraryService) DeleteItem(ctx context.Context, itemID, userID string) error {
	if err := s.repo.Delete(ctx, itemID, userID); err != nil {
		s.logger.ErrorContext(ctx, "刪除食譜庫項目失敗", "item_id", itemID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "食譜庫項目刪除成功", "item_id", itemID, "user_id", userID)
	return nil
}
