package trip

import (
	"context"
	"log/slog"
)

// TripMealService 定義行程伙食相關的業務邏輯介面。
type TripMealService interface {
	ListItems(ctx context.Context, tripID, userID string) ([]*TripMealItem, error)
	CreateItem(ctx context.Context, tripID, userID string, req *TripMealItem) (*TripMealItem, error)
	UpdateItem(ctx context.Context, tripID, itemID, userID string, req *TripMealItem) (*TripMealItem, error)
	DeleteItem(ctx context.Context, tripID, itemID, userID string) error
	ReplaceAllItems(ctx context.Context, tripID, userID string, items []*TripMealItem) error
}

type tripMealService struct {
	logger        *slog.Logger
	repo          TripMealRepository
	accessChecker TripAccessChecker
}

func NewTripMealService(logger *slog.Logger, repo TripMealRepository, accessChecker TripAccessChecker) TripMealService {
	return &tripMealService{
		logger:        logger.With("component", "trip_meal"),
		repo:          repo,
		accessChecker: accessChecker,
	}
}

func (s *tripMealService) ListItems(ctx context.Context, tripID, userID string) ([]*TripMealItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	return s.repo.ListByTripID(ctx, tripID)
}

func (s *tripMealService) CreateItem(ctx context.Context, tripID, userID string, req *TripMealItem) (*TripMealItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	req.TripID = tripID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	item, err := s.repo.Create(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立行程伙食失敗", "trip_id", tripID, "user_id", userID, "name", req.Name, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "行程伙食建立成功", "item_id", item.ID, "trip_id", tripID, "user_id", userID)
	return item, nil
}

func (s *tripMealService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *TripMealItem) (*TripMealItem, error) {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return nil, err
	}
	req.ID = itemID
	req.TripID = tripID
	req.UpdatedBy = userID
	item, err := s.repo.Update(ctx, req)
	if err != nil {
		s.logger.ErrorContext(ctx, "更新行程伙食失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return nil, err
	}
	s.logger.InfoContext(ctx, "行程伙食更新成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return item, nil
}

func (s *tripMealService) DeleteItem(ctx context.Context, tripID, itemID, userID string) error {
	if err := s.accessChecker.RequireMember(ctx, tripID, userID); err != nil {
		return err
	}
	if err := s.repo.Delete(ctx, itemID, tripID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程伙食失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "行程伙食刪除成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return nil
}

func (s *tripMealService) ReplaceAllItems(ctx context.Context, tripID, userID string, items []*TripMealItem) error {
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
