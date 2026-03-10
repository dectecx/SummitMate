package service

import (
	"context"
	"errors"

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

// GetTrip 取得特定行程詳細資料，目前限制只有成員或建立者能看 (保護公開行程另計)。
func (s *TripService) GetTrip(ctx context.Context, tripID, userID string) (*model.Trip, error) {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return s.tripRepo.GetByID(ctx, tripID)
}

// ListTrips 取得使用者建立或已加入的行程。
func (s *TripService) ListTrips(ctx context.Context, userID string) ([]*model.Trip, error) {
	return s.tripRepo.ListByUserID(ctx, userID)
}

// UpdateTrip 更新行程資料。
func (s *TripService) UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*model.Trip, error) {
	// 假設只有建立者或成員可以編輯
	if !s.isTripCreator(ctx, tripID, userID) && !s.isTripMember(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}

	existingTrip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
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

// DeleteTrip 刪除行程，只允許建立者刪除。
func (s *TripService) DeleteTrip(ctx context.Context, tripID, userID string) error {
	if !s.isTripCreator(ctx, tripID, userID) {
		return ErrUnauthorizedTripAccess
	}
	return s.tripRepo.DeleteByID(ctx, tripID)
}

// --- Trip Members ---

// ListMembers 取得行程的成員列表。
func (s *TripService) ListMembers(ctx context.Context, tripID, userID string) ([]*model.TripMember, error) {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return s.memberRepo.ListByTripID(ctx, tripID)
}

// AddMember 透過 Email 邀請使用者加入行程。
func (s *TripService) AddMember(ctx context.Context, tripID, userID, targetEmail string) (*model.TripMember, error) {
	// 驗證是否有權限新增 (只有成員或建立者可以邀人)
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
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

// RemoveMember 將成員移出行程。
func (s *TripService) RemoveMember(ctx context.Context, tripID, actionUserID, targetUserID string) error {
	// 如果自己退出就可以，如果是要踢人則必須是 Creator
	isSelfExit := actionUserID == targetUserID
	if !isSelfExit && !s.isTripCreator(ctx, tripID, actionUserID) {
		return ErrUnauthorizedTripAccess
	}

	// 不得移除 Creator
	if s.isTripCreator(ctx, tripID, targetUserID) {
		return ErrCannotRemoveCreator
	}

	return s.memberRepo.RemoveMember(ctx, tripID, targetUserID)
}

// --- Itinerary ---

// ListItinerary 取得行程表。
func (s *TripService) ListItinerary(ctx context.Context, tripID, userID string) ([]*model.ItineraryItem, error) {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
		return nil, ErrUnauthorizedTripAccess
	}
	return s.itineraryRepo.ListByTripID(ctx, tripID)
}

// AddItineraryItem 新增行程表節點。
func (s *TripService) AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*model.ItineraryItem, error) {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
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

// UpdateItineraryItem 更新行程表節點。
func (s *TripService) UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*model.ItineraryItem, error) {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
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

// DeleteItineraryItem 刪除行程表節點。
func (s *TripService) DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error {
	if !s.isTripMember(ctx, tripID, userID) && !s.isTripCreator(ctx, tripID, userID) {
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

// isTripCreator 判斷給定的 userID 是否為該行程的擁有者 (created_by 或是 user_id)。
func (s *TripService) isTripCreator(ctx context.Context, tripID, userID string) bool {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return false
	}
	return trip.UserID == userID
}

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
	StartDate   string
	EndDate     *string
	CoverImage  *string
	DayNames    []string
}

type TripUpdateRequest struct {
	Name        *string
	Description *string
	StartDate   *string
	EndDate     *string
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
