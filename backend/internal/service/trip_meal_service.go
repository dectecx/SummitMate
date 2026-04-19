package service

import (
	"context"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
	"summitmate/internal/trip"
)

// TripMealService 定義行程伙食相關的業務邏輯介面。
type TripMealService interface {
	ListItems(ctx context.Context, tripID, userID string) ([]*model.TripMealItem, error)
	CreateItem(ctx context.Context, tripID, userID string, req *model.TripMealItem) (*model.TripMealItem, error)
	UpdateItem(ctx context.Context, tripID, itemID, userID string, req *model.TripMealItem) (*model.TripMealItem, error)
	DeleteItem(ctx context.Context, tripID, itemID, userID string) error
	ReplaceAllItems(ctx context.Context, tripID, userID string, items []*model.TripMealItem) error
}

type tripMealService struct {
	logger     *slog.Logger
	repo       repository.TripMealRepository
	tripRepo   trip.TripRepository
	memberRepo trip.TripMemberRepository
}

func NewTripMealService(logger *slog.Logger, repo repository.TripMealRepository, tripRepo trip.TripRepository, memberRepo trip.TripMemberRepository) TripMealService {
	return &tripMealService{
		logger:     logger.With("component", "trip_meal"),
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *tripMealService) ListItems(ctx context.Context, tripID, userID string) ([]*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.repo.ListByTripID(ctx, tripID)
}

func (s *tripMealService) CreateItem(ctx context.Context, tripID, userID string, req *model.TripMealItem) (*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
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

func (s *tripMealService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *model.TripMealItem) (*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
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
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}
	if err := s.repo.Delete(ctx, itemID, tripID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程伙食失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "行程伙食刪除成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return nil
}

func (s *tripMealService) ReplaceAllItems(ctx context.Context, tripID, userID string, items []*model.TripMealItem) error {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
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

func (s *tripMealService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err == nil && trip.UserID == userID {
		return true
	}
	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err == nil {
		for _, m := range members {
			if m.UserID == userID {
				return true
			}
		}
	}
	return false
}
