package trip

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
)

// TripService 封裝行程相關的業務邏輯。
type TripService interface {
	CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*Trip, error)
	GetTrip(ctx context.Context, tripID, userID string) (*Trip, error)
	ListTrips(ctx context.Context, userID string) ([]*Trip, error)
	UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*Trip, error)
	DeleteTrip(ctx context.Context, tripID, userID string) error
	ListMembers(ctx context.Context, tripID, userID string) ([]*TripMember, error)
	AddMember(ctx context.Context, tripID, userID, targetEmail string) (*TripMember, error)
	RemoveMember(ctx context.Context, tripID, actionUserID, targetUserID string) error
	ListItinerary(ctx context.Context, tripID, userID string) ([]*ItineraryItem, error)
	AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error)
	UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error)
	DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error
}

type tripService struct {
	logger        *slog.Logger
	tripRepo      TripRepository
	memberRepo    TripMemberRepository
	itineraryRepo ItineraryRepository
	userRepo      auth.UserRepository
}

func NewTripService(
	logger *slog.Logger,
	tripRepo TripRepository,
	memberRepo TripMemberRepository,
	itineraryRepo ItineraryRepository,
	userRepo auth.UserRepository,
) TripService {
	return &tripService{
		logger:        logger.With("component", "trip"),
		tripRepo:      tripRepo,
		memberRepo:    memberRepo,
		itineraryRepo: itineraryRepo,
		userRepo:      userRepo,
	}
}

// --- Trip CRUD ---

func (s *tripService) CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*Trip, error) {
	trip := &Trip{
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		StartDate:   req.StartDate,
		EndDate:     req.EndDate,
		CoverImage:  req.CoverImage,
		IsActive:    false,
		DayNames:    req.DayNames,
		CreatedBy:   userID,
		UpdatedBy:   userID,
	}
	if trip.DayNames == nil {
		trip.DayNames = []string{}
	}

	createdTrip, err := s.tripRepo.Create(ctx, trip)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立行程失敗", "user_id", userID, "error", err)
		return nil, err
	}

	err = s.memberRepo.AddMember(ctx, createdTrip.ID, userID)
	if err != nil {
		s.logger.ErrorContext(ctx, "建立者加入行程成員失敗", "trip_id", createdTrip.ID, "user_id", userID, "error", err)
		return nil, err
	}

	s.logger.InfoContext(ctx, "行程建立成功", "trip_id", createdTrip.ID, "user_id", userID, "name", createdTrip.Name)
	return createdTrip, nil
}

func (s *tripService) GetTrip(ctx context.Context, tripID, userID string) (*Trip, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, apperror.ErrTripNotFound
		}
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return trip, nil
}

func (s *tripService) ListTrips(ctx context.Context, userID string) ([]*Trip, error) {
	return s.tripRepo.ListByUserID(ctx, userID)
}

func (s *tripService) UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*Trip, error) {
	existingTrip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, apperror.ErrTripNotFound
		}
		return nil, err
	}
	if existingTrip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		s.logger.WarnContext(ctx, "更新行程權限不足", "trip_id", tripID, "user_id", userID)
		return nil, apperror.ErrAccessDenied
	}

	if req.Name != nil {
		existingTrip.Name = *req.Name
	}
	if req.Description != nil {
		existingTrip.Description = req.Description
	}
	if req.StartDate != nil {
		existingTrip.StartDate = *req.StartDate
	}
	if req.EndDate != nil {
		existingTrip.EndDate = req.EndDate
	}
	if req.CoverImage != nil {
		existingTrip.CoverImage = req.CoverImage
	}
	if req.IsActive != nil {
		existingTrip.IsActive = *req.IsActive
	}
	if req.DayNames != nil {
		existingTrip.DayNames = *req.DayNames
	}
	existingTrip.UpdatedBy = userID

	updatedTrip, err := s.tripRepo.Update(ctx, existingTrip)
	if err != nil {
		s.logger.ErrorContext(ctx, "更新行程失敗", "trip_id", tripID, "user_id", userID, "error", err)
		return nil, err
	}

	s.logger.InfoContext(ctx, "行程更新成功", "trip_id", tripID, "user_id", userID)
	return updatedTrip, nil
}

func (s *tripService) DeleteTrip(ctx context.Context, tripID, userID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return apperror.ErrTripNotFound
		}
		return err
	}
	if trip.UserID != userID {
		s.logger.WarnContext(ctx, "刪除行程權限不足", "trip_id", tripID, "user_id", userID)
		return apperror.ErrAccessDenied
	}

	if err := s.tripRepo.DeleteByID(ctx, tripID); err != nil {
		s.logger.ErrorContext(ctx, "刪除行程失敗", "trip_id", tripID, "user_id", userID, "error", err)
		return err
	}

	s.logger.InfoContext(ctx, "行程刪除成功", "trip_id", tripID, "user_id", userID)
	return nil
}

// --- Trip Members ---

func (s *tripService) ListMembers(ctx context.Context, tripID, userID string) ([]*TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.memberRepo.ListByTripID(ctx, tripID)
}

func (s *tripService) AddMember(ctx context.Context, tripID, userID, targetEmail string) (*TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	targetUser, err := s.userRepo.GetByEmail(ctx, targetEmail)
	if err != nil {
		if errors.Is(err, auth.ErrNotFound) {
			return nil, apperror.ErrResourceNotFound.WithMessage("找不到該使用者")
		}
		return nil, err
	}

	err = s.memberRepo.AddMember(ctx, tripID, targetUser.ID)
	if err != nil {
		return nil, err
	}

	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	for _, m := range members {
		if m.UserID == targetUser.ID {
			return m, nil
		}
	}
	return nil, apperror.InternalError("新增成員後查詢失敗")
}

func (s *tripService) RemoveMember(ctx context.Context, tripID, actionUserID, targetUserID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}

	isSelfExit := actionUserID == targetUserID
	if !isSelfExit && trip.UserID != actionUserID {
		return apperror.ErrAccessDenied
	}

	if trip.UserID == targetUserID {
		return apperror.ErrCannotRemoveOwner
	}

	return s.memberRepo.RemoveMember(ctx, tripID, targetUserID)
}

// --- Itinerary ---

func (s *tripService) ListItinerary(ctx context.Context, tripID, userID string) ([]*ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.itineraryRepo.ListByTripID(ctx, tripID)
}

func (s *tripService) AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	item := &ItineraryItem{
		TripID:     tripID,
		Day:        req.Day,
		Name:       req.Name,
		EstTime:    req.EstTime,
		Altitude:   req.Altitude,
		Distance:   req.Distance,
		Note:       req.Note,
		ImageAsset: req.ImageAsset,
		CreatedBy:  &userID,
		UpdatedBy:  &userID,
	}

	return s.itineraryRepo.Create(ctx, item)
}

func (s *tripService) UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	existingItem, err := s.itineraryRepo.GetByID(ctx, itemID)
	if err != nil {
		return nil, apperror.ErrResourceNotFound.WithMessage("找不到行程表項目")
	}

	if existingItem.TripID != tripID {
		return nil, apperror.ErrBadRequest.WithMessage("行程表項目不屬於此行程")
	}

	existingItem.Day = req.Day
	existingItem.Name = req.Name
	existingItem.EstTime = req.EstTime
	existingItem.Altitude = req.Altitude
	existingItem.Distance = req.Distance
	existingItem.Note = req.Note
	existingItem.ImageAsset = req.ImageAsset
	existingItem.UpdatedBy = &userID

	return s.itineraryRepo.Update(ctx, existingItem)
}

func (s *tripService) DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}

	existingItem, err := s.itineraryRepo.GetByID(ctx, itemID)
	if err != nil {
		return apperror.ErrResourceNotFound.WithMessage("找不到行程表項目")
	}
	if existingItem.TripID != tripID {
		return apperror.ErrBadRequest.WithMessage("行程表項目不屬於此行程")
	}

	return s.itineraryRepo.DeleteByID(ctx, itemID)
}

// isTripMember 判斷給定的 userID 是否已經被加入該行程。
func (s *tripService) isTripMember(ctx context.Context, tripID, userID string) bool {
	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err != nil {
		return false
	}
	for _, m := range members {
		if m.UserID == userID {
			return true
		}
	}
	return false
}

// --- Requests models used in service logic ---

type TripCreateRequest struct {
	Name        string
	Description *string
	StartDate   time.Time
	EndDate     *time.Time
	CoverImage  *string
	DayNames    []string
}

type TripUpdateRequest struct {
	Name        *string
	Description *string
	StartDate   *time.Time
	EndDate     *time.Time
	CoverImage  *string
	IsActive    *bool
	DayNames    *[]string
}

type ItineraryItemRequest struct {
	Day        string
	Name       string
	EstTime    string
	Altitude   int32
	Distance   float64
	Note       string
	ImageAsset *string
}
