package service

import (
	"context"
	"log/slog"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type TripGearService struct {
	logger     *slog.Logger
	repo       *repository.TripGearRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewTripGearService(logger *slog.Logger, repo *repository.TripGearRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *TripGearService {
	return &TripGearService{
		logger:     logger.With("component", "trip_gear"),
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *TripGearService) ListItems(ctx context.Context, tripID, userID string) ([]*model.TripGearItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.repo.ListByTripID(ctx, tripID)
}

func (s *TripGearService) CreateItem(ctx context.Context, tripID, userID string, req *model.TripGearItem) (*model.TripGearItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
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

func (s *TripGearService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *model.TripGearItem) (*model.TripGearItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
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

func (s *TripGearService) DeleteItem(ctx context.Context, tripID, itemID, userID string) error {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}
	if err := s.repo.Delete(ctx, itemID, tripID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程裝備失敗", "item_id", itemID, "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}
	s.logger.InfoContext(ctx, "行程裝備刪除成功", "item_id", itemID, "trip_id", tripID, "user_id", userID)
	return nil
}

func (s *TripGearService) ReplaceAllItems(ctx context.Context, tripID, userID string, items []*model.TripGearItem) error {
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

func (s *TripGearService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
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
