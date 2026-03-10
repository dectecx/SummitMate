package service

import (
	"context"
	"errors"
	"time"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

var (
	ErrUnauthorizedTripAccess = errors.New("unauthorized access to trip")
	ErrCannotRemoveCreator    = errors.New("cannot remove the creator from the trip")
)

// TripService 封裝行程相關的業務邏輯。
type TripService struct {
	tripRepo      *repository.TripRepository
	memberRepo    *repository.TripMemberRepository
	itineraryRepo *repository.ItineraryRepository
	userRepo      *repository.UserRepository
}

// NewTripService 初始化 TripService。
func NewTripService(
	tripRepo *repository.TripRepository,
	memberRepo *repository.TripMemberRepository,
	itineraryRepo *repository.ItineraryRepository,
	userRepo *repository.UserRepository,
) *TripService {
	return &TripService{
		tripRepo:      tripRepo,
		memberRepo:    memberRepo,
		itineraryRepo: itineraryRepo,
		userRepo:      userRepo,
	}
}

// --- Trip CRUD ---

// CreateTrip 建立新行程，並且預設建立者成為行程成員。
func (s *TripService) CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*model.Trip, error) {
	trip := &model.Trip{
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		StartDate:   req.StartDate,
		EndDate:     req.EndDate,
		CoverImage:  req.CoverImage,
		IsActive:    false, // 預設未出發
		DayNames:    req.DayNames,
		CreatedBy:   userID,
		UpdatedBy:   userID,
	}
	if trip.DayNames == nil {
		trip.DayNames = []string{}
	}

	createdTrip, err := s.tripRepo.Create(ctx, trip)
	if err != nil {
		return nil, err
	}

	// 建立者自動加入為成員
	err = s.memberRepo.AddMember(ctx, createdTrip.ID, userID)
	if err != nil {
		return nil, err
	}

	return createdTrip, nil
}

func (s *TripService) GetTrip(ctx context.Context, tripID, userID string) (*model.Trip, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return trip, nil
}

// ListTrips 取得使用者建立或已加入的行程。
func (s *TripService) ListTrips(ctx context.Context, userID string) ([]*model.Trip, error) {
	return s.tripRepo.ListByUserID(ctx, userID)
}

func (s *TripService) UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*model.Trip, error) {
	existingTrip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if existingTrip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	// 更新允許被修改的欄位
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

	return s.tripRepo.Update(ctx, existingTrip)
}

func (s *TripService) DeleteTrip(ctx context.Context, tripID, userID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if trip.UserID != userID {
		return ErrUnauthorizedTripAccess
	}
	return s.tripRepo.DeleteByID(ctx, tripID)
}

// --- Trip Members ---

func (s *TripService) ListMembers(ctx context.Context, tripID, userID string) ([]*model.TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return s.memberRepo.ListByTripID(ctx, tripID)
}

func (s *TripService) AddMember(ctx context.Context, tripID, userID, targetEmail string) (*model.TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	// 驗證是否有權限新增 (只有成員或建立者可以邀人)
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	// 找尋目標使用者
	targetUser, err := s.userRepo.GetByEmail(ctx, targetEmail)
	if err != nil {
		return nil, err
	}

	// 加入行程
	err = s.memberRepo.AddMember(ctx, tripID, targetUser.ID)
	if err != nil {
		return nil, err
	}

	// 我們直接重拉一次整個列表，找到新增的成員回傳
	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	for _, m := range members {
		if m.UserID == targetUser.ID {
			return m, nil
		}
	}
	return nil, errors.New("failed to find member after adding")
}

func (s *TripService) RemoveMember(ctx context.Context, tripID, actionUserID, targetUserID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	
	// 如果自己退出就可以，如果是要踢人則必須是 Creator
	isSelfExit := actionUserID == targetUserID
	if !isSelfExit && trip.UserID != actionUserID {
		return ErrUnauthorizedTripAccess
	}

	// 不得移除 Creator
	if trip.UserID == targetUserID {
		return ErrCannotRemoveCreator
	}

	return s.memberRepo.RemoveMember(ctx, tripID, targetUserID)
}

// --- Itinerary ---

func (s *TripService) ListItinerary(ctx context.Context, tripID, userID string) ([]*model.ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return s.itineraryRepo.ListByTripID(ctx, tripID)
}

func (s *TripService) AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*model.ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	item := &model.ItineraryItem{
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

func (s *TripService) UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*model.ItineraryItem, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	existingItem, err := s.itineraryRepo.GetByID(ctx, itemID)
	if err != nil {
		return nil, err
	}

	if existingItem.TripID != tripID {
		return nil, errors.New("itinerary item does not belong to this trip")
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

func (s *TripService) DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if trip.UserID != userID && !s.isTripMember(ctx, tripID, userID) {
		return ErrUnauthorizedTripAccess
	}

	existingItem, err := s.itineraryRepo.GetByID(ctx, itemID)
	if err != nil {
		return err
	}
	if existingItem.TripID != tripID {
		return errors.New("itinerary item does not belong to this trip")
	}

	return s.itineraryRepo.DeleteByID(ctx, itemID)
}

// --- 輔助函式 ---



// isTripMember 判斷給定的 userID 是否已經被加入該行程。
func (s *TripService) isTripMember(ctx context.Context, tripID, userID string) bool {
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
// 定義 Service 專屬的 Request struct, handler 那邊再對應過來
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
