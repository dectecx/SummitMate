package service

import (
	"context"

	"summitmate/internal/apperror"
	"summitmate/internal/model"
	"summitmate/internal/repository"
)

type TripGearService struct {
	repo       *repository.TripGearRepository
	tripRepo   *repository.TripRepository
	memberRepo *repository.TripMemberRepository
}

func NewTripGearService(repo *repository.TripGearRepository, tripRepo *repository.TripRepository, memberRepo *repository.TripMemberRepository) *TripGearService {
	return &TripGearService{
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
	return s.repo.Create(ctx, req)
}

func (s *TripGearService) UpdateItem(ctx context.Context, tripID, itemID, userID string, req *model.TripGearItem) (*model.TripGearItem, error) {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	req.ID = itemID
	req.TripID = tripID
	req.UpdatedBy = userID
	return s.repo.Update(ctx, req)
}

func (s *TripGearService) DeleteItem(ctx context.Context, tripID, itemID, userID string) error {
	if !s.isTripMemberOrCreator(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}
	return s.repo.Delete(ctx, itemID, tripID)
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
