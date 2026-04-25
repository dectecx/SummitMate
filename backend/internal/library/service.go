package library

import (
	"context"
	"log/slog"
)

// GearLibraryService 定義裝備庫相關的業務邏輯介面。
type GearLibraryService interface {
	CreateItem(ctx context.Context, userID string, item *GearLibraryItem) (*GearLibraryItem, error)
	GetItem(ctx context.Context, id string, userID string) (*GearLibraryItem, error)
	ListItems(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*GearLibraryItem, int, bool, error)
	UpdateItem(ctx context.Context, id string, userID string, item *GearLibraryItem) (*GearLibraryItem, error)
	DeleteItem(ctx context.Context, id string, userID string) error
	ReplaceAllItems(ctx context.Context, userID string, items []*GearLibraryItem) error
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

func (s *gearLibraryService) CreateItem(ctx context.Context, userID string, item *GearLibraryItem) (*GearLibraryItem, error) {
	item.UserID = userID
	item.CreatedBy = userID
	item.UpdatedBy = userID
	return s.repo.Create(ctx, item)
}

func (s *gearLibraryService) GetItem(ctx context.Context, id string, userID string) (*GearLibraryItem, error) {
	return s.repo.GetByID(ctx, id, userID)
}

func (s *gearLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*GearLibraryItem, int, bool, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived, page, limit, search)
}

func (s *gearLibraryService) UpdateItem(ctx context.Context, id string, userID string, item *GearLibraryItem) (*GearLibraryItem, error) {
	item.ID = id
	item.UserID = userID
	item.UpdatedBy = userID
	return s.repo.Update(ctx, item)
}

func (s *gearLibraryService) DeleteItem(ctx context.Context, id string, userID string) error {
	return s.repo.Delete(ctx, id, userID)
}

func (s *gearLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*GearLibraryItem) error {
	return s.repo.ReplaceAll(ctx, userID, items)
}

// MealLibraryService 定義餐食庫相關的業務邏輯介面。
type MealLibraryService interface {
	CreateItem(ctx context.Context, userID string, item *MealLibraryItem) (*MealLibraryItem, error)
	GetItem(ctx context.Context, id string, userID string) (*MealLibraryItem, error)
	ListItems(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*MealLibraryItem, int, bool, error)
	UpdateItem(ctx context.Context, id string, userID string, item *MealLibraryItem) (*MealLibraryItem, error)
	DeleteItem(ctx context.Context, id string, userID string) error
	ReplaceAllItems(ctx context.Context, userID string, items []*MealLibraryItem) error
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

func (s *mealLibraryService) CreateItem(ctx context.Context, userID string, item *MealLibraryItem) (*MealLibraryItem, error) {
	item.UserID = userID
	item.CreatedBy = userID
	item.UpdatedBy = userID
	return s.repo.Create(ctx, item)
}

func (s *mealLibraryService) GetItem(ctx context.Context, id string, userID string) (*MealLibraryItem, error) {
	return s.repo.GetByID(ctx, id, userID)
}

func (s *mealLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool, page int, limit int, search string) ([]*MealLibraryItem, int, bool, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived, page, limit, search)
}

func (s *mealLibraryService) UpdateItem(ctx context.Context, id string, userID string, item *MealLibraryItem) (*MealLibraryItem, error) {
	item.ID = id
	item.UserID = userID
	item.UpdatedBy = userID
	return s.repo.Update(ctx, item)
}

func (s *mealLibraryService) DeleteItem(ctx context.Context, id string, userID string) error {
	return s.repo.Delete(ctx, id, userID)
}

func (s *mealLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*MealLibraryItem) error {
	return s.repo.ReplaceAll(ctx, userID, items)
}
