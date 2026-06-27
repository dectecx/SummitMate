package trip

import (
	"context"
	"log/slog"
)

// TripGearService 定義行程裝備相關的業務邏輯介面。
type TripGearService interface {
	ListItems(ctx context.Context, tripID, userID string) ([]*TripGearItem, error)
	CreateItem(ctx context.Context, tripID, userID string, req *TripGearItem) (*TripGearItem, error)
	UpdateItem(ctx context.Context, tripID, itemID, userID string, req *TripGearItem) (*TripGearItem, error)
	DeleteItem(ctx context.Context, tripID, itemID, userID string) error
	ReplaceAllItems(ctx context.Context, tripID, userID string, items []*TripGearItem) error
}

type tripGearService struct {
	logger        *slog.Logger
	repo          TripGearRepository
	accessChecker TripAccessChecker
}

func NewTripGearService(logger *slog.Logger, repo TripGearRepository, accessChecker TripAccessChecker) TripGearService {
	return &tripGearService{
		logger:        logger.With("component", "trip_gear"),
		repo:          repo,
		accessChecker: accessChecker,
	}
}

func (s *tripGearService) ListItems(ctx context.Context, tripID, userID string) ([]*TripGearItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	return s.repo.ListByTripID(ctx, tripID)
}

func (s *tripGearService) CreateItem(ctx context.Context, tripID, userID string, req *TripGearItem) (*TripGearItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	req.TripID = tripID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	item, err := s.repo.Create(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立行程裝備失敗", "trip_id", tripID, "user_id", userID, "name", req.Name, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "行程裝備建立成功", "item_id", item.ID, "trip_id", tripID, "user_id", userID)
	return item, nil
}

func (s *tripGearService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *TripGearItem) (*TripGearItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	req.ID = itemID
	req.TripID = tripID
	req.UpdatedBy = userID
	item, err := s.repo.Update(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "更新行程裝備失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "行程裝備更新成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return item, nil
}

func (s *tripGearService) DeleteItem(ctx context.Context, tripID, itemID, userID string) error {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return err
	}
	if err := s.repo.Delete(ctx, itemID, tripID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程裝備失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "行程裝備刪除成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return nil
}

func (s *tripGearService) ReplaceAllItems(ctx context.Context, tripID, userID string, items []*TripGearItem) error {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return err
	}

	for _, item := range items {
		item.TripID = tripID
		if item.CreatedBy == "" {
			item.CreatedBy = userID
		}
		item.UpdatedBy = userID
	}

	return s.repo.ReplaceAll(ctx, tripID, items)
}
