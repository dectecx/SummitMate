package service

import (
	"context"
	"log/slog"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

// GearLibraryService 定義裝備庫相關的業務邏輯介面。
type GearLibraryService interface {
	CreateItem(ctx context.Context, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error)
	GetItem(ctx context.Context, itemID, userID string) (*model.GearLibraryItem, error)
	ListItems(ctx context.Context, userID string, includeArchived bool) ([]*model.GearLibraryItem, error)
	UpdateItem(ctx context.Context, itemID, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error)
	ReplaceAllItems(ctx context.Context, userID string, items []*model.GearLibraryItem) error
	DeleteItem(ctx context.Context, itemID, userID string) error
}

type gearLibraryService struct {
	logger *slog.Logger
	repo   repository.GearLibraryRepository
}

func NewGearLibraryService(logger *slog.Logger, repo repository.GearLibraryRepository) GearLibraryService {
	return &gearLibraryService{
		logger: logger.With("component", "gear_library"),
		repo:   repo,
	}
}

func (s *gearLibraryService) CreateItem(ctx context.Context, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error) {
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

func (s *gearLibraryService) GetItem(ctx context.Context, itemID, userID string) (*model.GearLibraryItem, error) {
	return s.repo.GetByID(ctx, itemID, userID)
}

func (s *gearLibraryService) ListItems(ctx context.Context, userID string, includeArchived bool) ([]*model.GearLibraryItem, error) {
	return s.repo.ListByUserID(ctx, userID, includeArchived)
}

func (s *gearLibraryService) UpdateItem(ctx context.Context, itemID, userID string, req *model.GearLibraryItem) (*model.GearLibraryItem, error) {
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

func (s *gearLibraryService) ReplaceAllItems(ctx context.Context, userID string, items []*model.GearLibraryItem) error {
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
