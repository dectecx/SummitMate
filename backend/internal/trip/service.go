package trip

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	"summitmate/internal/common/ptrutil"
	"summitmate/internal/database"
)

// TripService 封裝行程相關的業務邏輯。
type TripService interface {
	CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*Trip, error)
	GetTrip(ctx context.Context, tripID, userID string) (*Trip, error)
	ListTrips(ctx context.Context, userID string, page int, limit int, search string) ([]*Trip, int, bool, error)
	UpdateTrip(ctx context.Context, tripID, userID string, req *TripUpdateRequest) (*Trip, error)
	DeleteTrip(ctx context.Context, tripID, userID string) error
	ListMembers(ctx context.Context, tripID, userID string) ([]*TripMember, error)
	InviteMemberByEmail(ctx context.Context, tripID, userID, email string) (*TripMember, error)
	AddMember(ctx context.Context, tripID, userID, targetUserID string) (*TripMember, error)
	RemoveMember(ctx context.Context, tripID, actionUserID, targetUserID string) error
	BatchAddMembers(ctx context.Context, tripID, actionUserID string, targetUserIDs []string) error
	BatchRemoveMembers(ctx context.Context, tripID, actionUserID string, targetUserIDs []string) error
	ListItinerary(ctx context.Context, tripID, userID string) ([]*ItineraryItem, error)
	AddItineraryItem(ctx context.Context, tripID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error)
	UpdateItineraryItem(ctx context.Context, tripID, itemID, userID string, req *ItineraryItemRequest) (*ItineraryItem, error)
	DeleteItineraryItem(ctx context.Context, tripID, itemID, userID string) error
	// Meal Plan Days
	ListMealPlanDays(ctx context.Context, tripID, userID string) ([]*MealPlanDay, error)
	AddMealPlanDay(ctx context.Context, tripID, userID string, name string, linkedDay *string) (*MealPlanDay, error)
	UpdateMealPlanDay(ctx context.Context, tripID, dayID, userID string, name string, linkedDay *string) (*MealPlanDay, error)
	DeleteMealPlanDay(ctx context.Context, tripID, dayID, userID string) error
}

type tripService struct {
	logger        *slog.Logger
	db            database.Beginner
	tripRepo      TripRepository
	memberRepo    TripMemberRepository
	itineraryRepo ItineraryRepository
	mealDayRepo   TripMealPlanDayRepository
	userRepo      auth.UserRepository
}

func NewTripService(
	logger *slog.Logger,
	db database.Beginner,
	tripRepo TripRepository,
	memberRepo TripMemberRepository,
	itineraryRepo ItineraryRepository,
	mealDayRepo TripMealPlanDayRepository,
	userRepo auth.UserRepository,
) TripService {
	return &tripService{
		logger:        logger.With("component", "trip"),
		db:            db,
		tripRepo:      tripRepo,
		memberRepo:    memberRepo,
		itineraryRepo: itineraryRepo,
		mealDayRepo:   mealDayRepo,
		userRepo:      userRepo,
	}
}

// --- Trip CRUD ---

func (s *tripService) CreateTrip(ctx context.Context, userID string, req *TripCreateRequest) (*Trip, error) {
	var createdTrip *Trip

	err := database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
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

		var err error
		createdTrip, err = s.tripRepo.Create(txCtx, trip)
		if err != nil {
			s.logger.ErrorContext(txCtx, "建立行程失敗", "user_id", userID, "error", err)
			return err
		}

		err = s.memberRepo.AddMember(txCtx, createdTrip.ID, userID)
		if err != nil {
			s.logger.ErrorContext(txCtx, "建立者加入行程成員失敗", "trip_id", createdTrip.ID, "user_id", userID, "error", err)
			return err
		}

		// 預設建立一個 D1 的糧食計畫天數
		defaultDay := &MealPlanDay{
			TripID: createdTrip.ID,
			Name:   "D1",
		}
		// 如果行程天數中有 D1，則自動綁定
		for _, dn := range createdTrip.DayNames {
			if dn == "D1" {
				linked := "D1"
				defaultDay.LinkedItineraryDay = &linked
				break
			}
		}
		_, err = s.mealDayRepo.Create(txCtx, defaultDay)
		if err != nil {
			s.logger.ErrorContext(txCtx, "建立預設糧食計畫天數失敗", "trip_id", createdTrip.ID, "error", err)
			return err
		}

		return nil
	})

	if err != nil {
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

	// 載入糧食計畫天數
	mealDays, err := s.mealDayRepo.ListByTripID(ctx, tripID)
	if err != nil {
		s.logger.ErrorContext(ctx, "載入糧食計畫天數失敗", "trip_id", tripID, "error", err)
		return nil, apperror.InternalError("載入糧食計畫失敗").Wrap(err)
	}
	trip.MealPlanDays = make([]MealPlanDay, len(mealDays))
	for i, d := range mealDays {
		// 如果有綁定行程天數，確保名稱同步
		if d.LinkedItineraryDay != nil {
			found := false
			for _, dn := range trip.DayNames {
				if dn == *d.LinkedItineraryDay {
					d.Name = dn
					found = true
					break
				}
			}
			// 如果沒找到對應的行程天數，表示該連結已失效（可能行程天數被改名或刪除）
			if !found {
				s.logger.WarnContext(ctx, "糧食計畫天數綁定的行程天數已不存在", "trip_id", tripID, "meal_plan_day_id", d.ID, "linked_day", *d.LinkedItineraryDay)
				d.LinkedItineraryDay = nil
			}
		}
		trip.MealPlanDays[i] = *d
	}

	return trip, nil
}

func (s *tripService) ListTrips(ctx context.Context, userID string, page int, limit int, search string) ([]*Trip, int, bool, error) {
	return s.tripRepo.ListByUserID(ctx, userID, page, limit, search)
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

	ptrutil.AssignIfPresent(&existingTrip.Name, req.Name)
	ptrutil.AssignPtrIfPresent(&existingTrip.Description, req.Description)
	ptrutil.AssignIfPresent(&existingTrip.StartDate, req.StartDate)
	ptrutil.AssignPtrIfPresent(&existingTrip.EndDate, req.EndDate)
	ptrutil.AssignPtrIfPresent(&existingTrip.CoverImage, req.CoverImage)
	ptrutil.AssignIfPresent(&existingTrip.IsActive, req.IsActive)
	existingTrip.UpdatedBy = userID

	var updatedTrip *Trip
	err = database.WithTransaction(ctx, s.db, func(txCtx context.Context) error {
		var err error
		updatedTrip, err = s.tripRepo.Update(txCtx, existingTrip, req.LastUpdatedAt)
		if err != nil {
			return err
		}

		if req.DayNames != nil {
			existingTrip.DayNames = *req.DayNames
			// 檢查是否有糧食計畫天數綁定了已不存在的行程天數
			mealDays, err := s.mealDayRepo.ListByTripID(txCtx, tripID)
			if err == nil {
				for _, md := range mealDays {
					if md.LinkedItineraryDay != nil {
						found := false
						for _, dn := range existingTrip.DayNames {
							if dn == *md.LinkedItineraryDay {
								found = true
								break
							}
						}
						if !found {
							// 取消連結
							md.LinkedItineraryDay = nil
							if _, err := s.mealDayRepo.Update(txCtx, md); err != nil {
								return err
							}
						}
					}
				}
			}
		}
		return nil
	})

	if err != nil {
		if errors.Is(err, ErrNotFound) {
			// 如果提供了 LastUpdatedAt 但找不到對應行，表示 updated_at 已變動 (或是行程被刪除)
			if req.LastUpdatedAt != nil {
				return nil, apperror.ErrUpdateConflict
			}
			return nil, apperror.ErrTripNotFound
		}
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

func (s *tripService) InviteMemberByEmail(ctx context.Context, tripID, userID, targetEmail string) (*TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	// 只有團長可邀請
	if trip.UserID != userID {
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

func (s *tripService) AddMember(ctx context.Context, tripID, userID, targetUserID string) (*TripMember, error) {
	trip, err := s.tripRepo.GetByID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	// 只有團長可加人
	if trip.UserID != userID {
		return nil, apperror.ErrAccessDenied
	}

	// 防呆：先檢查是否已是成員
	isMember, err := s.memberRepo.IsMember(ctx, tripID, targetUserID)
	if err == nil && isMember {
		s.logger.DebugContext(ctx, "使用者已在行程中", "trip_id", tripID, "user_id", targetUserID)
	} else {
		if err := s.memberRepo.AddMember(ctx, tripID, targetUserID); err != nil {
			return nil, err
		}
	}

	members, err := s.memberRepo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, err
	}
	for _, m := range members {
		if m.UserID == targetUserID {
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

// BatchAddMembers 批次新增多位成員。
func (s *tripService) BatchAddMembers(ctx context.Context, tripID, actionUserID string, targetUserIDs []string) error {
	if len(targetUserIDs) == 0 {
		return nil
	}

	// 檢查權限 (只有 Owner 可以批次新增成員)
	role, err := s.memberRepo.GetRole(ctx, tripID, actionUserID)
	if err != nil {
		return err
	}
	if role != RoleOwner {
		return apperror.ErrTripAccessDenied
	}

	return s.memberRepo.BatchAddMembers(ctx, tripID, targetUserIDs)
}

// BatchRemoveMembers 批次移除多位成員。
func (s *tripService) BatchRemoveMembers(ctx context.Context, tripID, actionUserID string, targetUserIDs []string) error {
	if len(targetUserIDs) == 0 {
		return nil
	}

	// 檢查權限 (只有 Owner 可以批次移除成員)
	role, err := s.memberRepo.GetRole(ctx, tripID, actionUserID)
	if err != nil {
		return err
	}
	if role != RoleOwner {
		return apperror.ErrTripAccessDenied
	}

	return s.memberRepo.BatchRemoveMembers(ctx, tripID, targetUserIDs)
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
	if trip.UserID != userID {
		role, err := s.memberRepo.GetRole(ctx, tripID, userID)
		if err != nil || (role != "leader" && role != "guide") {
			return apperror.ErrAccessDenied
		}
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

// --- Meal Plan Days ---

func (s *tripService) ListMealPlanDays(ctx context.Context, tripID, userID string) ([]*MealPlanDay, error) {
	if !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}
	return s.mealDayRepo.ListByTripID(ctx, tripID)
}

func (s *tripService) AddMealPlanDay(ctx context.Context, tripID, userID string, name string, linkedDay *string) (*MealPlanDay, error) {
	if !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	// 驗證連結的天數是否存在
	if linkedDay != nil {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil {
			return nil, err
		}
		found := false
		for _, dn := range trip.DayNames {
			if dn == *linkedDay {
				name = dn // 強制使用行程天數的名稱
				found = true
				break
			}
		}
		if !found {
			return nil, errors.New("綁定的行程天數不存在")
		}
	}

	day := &MealPlanDay{
		TripID:             tripID,
		Name:               name,
		LinkedItineraryDay: linkedDay,
	}

	return s.mealDayRepo.Create(ctx, day)
}

func (s *tripService) UpdateMealPlanDay(ctx context.Context, tripID, dayID, userID string, name string, linkedDay *string) (*MealPlanDay, error) {
	if !s.isTripMember(ctx, tripID, userID) {
		return nil, apperror.ErrAccessDenied
	}

	existing, err := s.mealDayRepo.GetByID(ctx, dayID, tripID)
	if err != nil {
		return nil, err
	}

	// 驗證連結的天數是否存在
	if linkedDay != nil {
		trip, err := s.tripRepo.GetByID(ctx, tripID)
		if err != nil {
			return nil, err
		}
		found := false
		for _, dn := range trip.DayNames {
			if dn == *linkedDay {
				name = dn // 強制使用行程天數的名稱
				found = true
				break
			}
		}
		if !found {
			return nil, errors.New("綁定的行程天數不存在")
		}
	}

	existing.Name = name
	existing.LinkedItineraryDay = linkedDay

	return s.mealDayRepo.Update(ctx, existing)
}

func (s *tripService) DeleteMealPlanDay(ctx context.Context, tripID, dayID, userID string) error {
	if !s.isTripMember(ctx, tripID, userID) {
		return apperror.ErrAccessDenied
	}

	existing, err := s.mealDayRepo.GetByID(ctx, dayID, tripID)
	if err != nil {
		return err
	}

	// 如果是綁定行程的天數，不能直接刪除糧食天數 (必須從行程那邊刪除天數來觸發解綁)
	if existing.LinkedItineraryDay != nil {
		return apperror.New(http.StatusBadRequest, apperror.TypeInvalidReq, "linked_day_deletion_forbidden", "此天數已綁定行程，請至行程管理中修改或刪除").WithParam("linked_itinerary_day")
	}

	// 實作建議：資料庫已設定 ON DELETE CASCADE，故刪除天數時會自動刪除相關餐點。
	return s.mealDayRepo.Delete(ctx, dayID, tripID)
}

// isTripMember 判斷給定的 userID 是否已加入該行程。
func (s *tripService) isTripMember(ctx context.Context, tripID, userID string) bool {
	isMember, err := s.memberRepo.IsMember(ctx, tripID, userID)
	if err != nil {
		return false
	}
	return isMember
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
	Name          *string
	Description   *string
	StartDate     *time.Time
	EndDate       *time.Time
	CoverImage    *string
	IsActive      *bool
	DayNames      *[]string
	LastUpdatedAt *time.Time
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
