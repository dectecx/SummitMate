package service

import (
	"context"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type TripMealService struct {
	repo       *repository.TripMealRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewTripMealService(repo *repository.TripMealRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *TripMealService {
	return &TripMealService{
		repo:       repo,
		tripRepo:   tripRepo,
		memberRepo: memberRepo,
	}
}

func (s *TripMealService) ListItems(ctx context.Context, tripID, userID string) ([]*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.repo.ListByTripID(ctx, tripID)
}

func (s *TripMealService) CreateItem(ctx context.Context, tripID, userID string, req *model.TripMealItem) (*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	req.TripID = tripID
	req.CreatedBy = userID
	req.UpdatedBy = userID
	return s.repo.Create(ctx, req)
}

func (s *TripMealService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *model.TripMealItem) (*model.TripMealItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	req.ID = itemID
	req.TripID = tripID
	req.UpdatedBy = userID
	return s.repo.Update(ctx, req)
}

func (s *TripMealService) DeleteItem(ctx context.Context, tripID, itemID, userID string) error {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}
	return s.repo.Delete(ctx, itemID, tripID)
}

func (s *TripMealService) ReplaceAllItems(ctx context.Context, tripID, userID string, items []*model.TripMealItem) error {
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

func (s *TripMealService) isTripMemberOrCreator(ctx context.Context, tripID, userID string) bool {
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
